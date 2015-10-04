use asupcouk_asup;
DROP PROCEDURE IF EXISTS sr_distance;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$
CREATE PROCEDURE sr_distance(sr_gameno INT, sr_powername VARCHAR(16), sr_terrname_from VARCHAR(25), sr_terrname_to VARCHAR(25), OUT sr_distance INT)
BEGIN
sproc:BEGIN

-- Procedure to get distances from a territory
-- Setting terrname_to as Boomer allows to calculate as the crow flies distance
-- $Id: sr_distance.sql 242 2014-07-13 13:48:48Z paul $
DECLARE procname TEXT DEFAULT "SR_DISTANCE";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_terrno_from INT DEFAULT 0;
DECLARE sr_terrtype_from TEXT DEFAULT "";
DECLARE sr_power_terrtype TEXT DEFAULT "";
DECLARE sr_terrno_to INT DEFAULT 0;
DECLARE current_node INT DEFAULT 0;
DECLARE sr_ret_userno INT DEFAULT null;
DECLARE sr_strat_tech INT DEFAULT 0;
DECLARE sr_homes INT DEFAULT 0;
DECLARE sr_i INT DEFAULT 0;

DROP TABLE IF EXISTS tmp_src;
DROP TABLE IF EXISTS tmp_dest;
DROP TABLE IF EXISTS tmp_rede;
DROP TABLE IF EXISTS tmp_final;

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno < 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_DISTANCE", Concat("<FAIL><Reason>Invalid Game</Reason><Gameno>",sr_gameno,"</Gameno></FAIL>"));
    Leave sproc;
End If;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check powername
IF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N') and sr_powername != 'WARHEAD' THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, procname
           ,Concat("<FAIL><Reason>Invalid powername</Reason><PowerName>",sr_powername,"</PowerName></FAIL>")
           );
    LEAVE sproc;
END IF;
Select userno, strategic_tech Into sr_userno, sr_strat_tech From sp_resource Where gameno=sr_gameno and powername=sr_powername;
Select terrtype Into sr_power_terrtype From sp_powers Where powername=sr_powername;
-- Check for owned home territories redeploy
Select Count(*)>0 Into sr_homes 
From sp_board b, sp_places p, sp_powers pw 
Where b.userno=sr_userno 
 and b.terrno=p.terrno 
 and p.terrtype=sr_power_terrtype
;

-- Check territory names
IF Upper(sr_terrname_from) not in (Select Upper(terrname) From sp_places) THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, procname
            ,Concat("<FAIL><Reason>Invalid from territory</Reason>"
                   ,sf_fxml("TerritoryName",sr_terrname_from)
                   ,"</FAIL>"));
    LEAVE sproc;
END IF;
IF sr_terrname_to not in (Select terrname From sp_places) and sr_terrname_to not in ('ALL','March','Sail','Transport','Amphibious','Fly','Ground','Naval','Land','Sea','Aerial','Home','Boomer') THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, procname
            ,Concat("<FAIL><Reason>Invalid to territory</Reason>"
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,"</FAIL>"));
    LEAVE sproc;
END IF;
Select terrno, terrtype Into sr_terrno_from, sr_terrtype_from From sp_places Where Upper(terrname)=Upper(sr_terrname_from);
-- Set defauly terrno_to and change if it actually exists....
Create Temporary Table tmp_final As
Select terrno
From sp_places p
Left Join sp_powers pw On p.terrtype=pw.terrtype
Where terrname=sr_terrname_to
 or (sr_terrname_to='Home' and powername=sr_powername)
;

IF @sr_debug!='N' THEN 
	Select "Starting", sr_terrno_from, sr_terrtype_from, terrno, sr_power_terrtype, sr_homes, sr_strat_tech
	From    tmp_final
	; 
END IF;

-- Get info about all territories
Create Temporary Table tmp_src As
Select  terrno, terrname, terrtype, major, minor, passuser, powername, userno
        ,case when terrno=sr_terrno_from then 0 else null end As cost
        ,0 As calced
        ,Case                                             -- Can user get through territory
          When sr_powername='WARHEAD' Then 1              -- Warheads go anywhere
          When userno<-1 Then 0                           -- Not through nuked territories
          When sr_userno=passuser Then 1                  -- If they have ROP
		  When userno=0 and Length(terrtype)=3 Then 1     -- If it is an empty sea
		  When userno=sr_userno Then 1                    -- If they own the territory
		  Else 0
		 End As okThrough
        ,Case                                             -- Can user attack
          When userno != sr_userno and userno > -2 Then 1 -- If they do not own the territory
          When sr_strat_tech=5 and userno < -7 Then 1     -- If it is a nuked territory and they have tech
		  When sr_userno=passuser and userno=-10 Then 1   -- If it is an owned neutroned territory
		  Else 0                       
		 End As okAttack
        ,Case                                             -- Can a warhead land
          When userno>-2 Then 1                           -- If not nuked
          Else 0
         End okWarhead
From    sv_map
Where   gameno=sr_gameno
 and info=1
 and (userno >= -1
      or (userno=-10 and passuser = sr_userno)
      or (userno in (-9,-10) and (sr_strat_tech = 5))
      or (userno in (-9,-10) and terrno!=sr_terrno_to and (sr_powername='WARHEAD' or sr_terrname_to='Boomer'))
      )
;

IF @sr_debug='X' THEN Select *, "Initial tmp_src" From tmp_src; END IF;

-- Mark calculated that can not be passed through
Update tmp_src
Set    calced=1
Where  userno not in (sr_userno,Case When Length(sr_terrtype_from)=3 Then 0 Else sr_userno End)
 and   passuser != sr_userno
 and   sr_terrname_to != 'Boomer'
 and   sr_powername != 'WARHEAD'
;

IF @sr_debug='X' THEN Select *, "Close off territories" From tmp_src; END IF;

-- Create redeploys table
Create Temporary Table tmp_rede As
Select b.terrno
From   sp_board b, sp_orders o, sp_orders o2, sp_places p
Where b.gameno=sr_gameno
 and o.gameno=sr_gameno
 and o.userno=sr_userno
 and o2.gameno=sr_gameno
 and o2.userno=sr_userno
 and o2.ordername='MA_000'
 and o2.order_code='Waiting for redeploy'
 and b.terrno=p.terrno
 and Length(terrtype)=(Case When sr_terrname_to='Sail' Then 3 When sr_terrname_to in ('March', 'Transport', 'Fly') Then 4 Else Length(terrtype) End)
 and b.userno!=sr_userno
 and b.major=0 and b.minor=0
 and o.ordername='REDEPLOY'
 and Concat(' ',ExtractValue(o.order_code,'/Terrno'),' ') like Concat('% ',b.terrno,' %')
;
IF @sr_debug!='N' THEN Select *, "Redeploys" From tmp_rede; END IF;

-- Output for flying
IF sr_terrname_to in ('Fly','Aerial') THEN
    Update tmp_src
    Set cost=Case
              When sr_terrname_to = 'Fly' Then (userno=sr_userno
                                                or (userno=-10 and passuser=sr_userno)
                                                )
                                               and Length(terrtype)=4
                                               and terrno!=sr_terrno_from
              Else ((userno!=sr_userno and userno >= -1)
					or (sr_strat_tech=5 and userno in (-9,-10))
				   ) and Length(terrtype)=4
             End
        ,calced=1
    ;
ELSE
    -- START DIJKSTRA'S ALGORITHM
    Set sr_distance = 0;

    -- Set destination table
    Create Temporary Table tmp_dest As Select * From tmp_src;

    -- Start processing from initial territory
    Set current_node = sr_terrno_from;

    dijkstra: WHILE current_node is not null and sr_i < 1000 DO
      BEGIN
        Set sr_i=sr_i+1;

        -- Calculate distance from current node
        Update tmp_src src
        Join sp_ocean_borders o On o.terrno_from=src.terrno
        Join tmp_dest dest On o.terrno_to=dest.terrno
        Set dest.cost = Case
                         When dest.cost is null Then src.cost+distance
                         When src.cost+distance < dest.cost Then src.cost+distance
                         Else dest.cost
                        End
        Where src.terrno = current_node
              and (dest.cost is null or src.cost + distance < dest.Cost)
              and (src.cost=0 
                   or (Length(sr_terrtype_from)=Length(dest.terrtype) and Length(src.terrtype)=Length(dest.terrtype)) 
                   or sr_terrname_to='Home'
				   or sr_powername='WARHEAD'
                   or sr_terrname_to='Boomer'
                   )
              -- and dest.calced = 0
        ;

        -- Mark current node as complete
        Update tmp_dest
        Set    calced = 1
        Where  terrno = current_node
         -- or (cost is not null and calced=0 and userno not in (sr_userno,Case When Length(sr_terrtype_from)=3 Then 0 Else sr_userno End) and passuser!=sr_userno)
        ;

        -- Refresh source table
        Drop Temporary Table tmp_src;
        Create Temporary Table tmp_src As Select * From tmp_dest;

        IF @sr_debug='X' THEN
            Select src.terrno, src.terrname, src.powername, src.cost, src.calced
                   ,terrno_from, terrno_to
                   ,dest.terrname, dest.terrtype, dest.passuser, dest.powername, dest.cost, dest.calced
                   ,Case When dest.cost is null Then src.cost+1 When src.cost+1 < dest.cost Then src.cost+1 Else dest.cost End
                   ,Length(sr_terrtype_from),Length(dest.terrtype), Concat("NODE:",current_node)
            From tmp_src src
            Join sp_ocean_borders o On o.terrno_from=src.terrno
            Join tmp_dest dest On o.terrno_to=dest.terrno
            Where src.terrno = current_node
			  and (dest.cost is null or src.cost + 1 < dest.Cost)
              and (src.cost=0 
                   or (Length(sr_terrtype_from)=Length(dest.terrtype) and Length(src.terrtype)=Length(dest.terrtype)) 
                   or sr_terrname_to='Home'
				   or sr_powername='WARHEAD'
                   or sr_terrname_to='Boomer'
                   )
              and dest.calced = 0            ;
        END IF;

        -- Get next node, with lowest distance
        Set current_node = (Select terrno
                            From   tmp_src
                            Where  calced = 0
                                   and cost is not null
                                   and (   userno=sr_userno
                                        or (userno = 0 and Length(terrtype)=3)
                                        or passuser=sr_userno
                                        or sr_powername='WARHEAD'
                                        or sr_terrno_to='Boomer'
                                        )
                            Order By cost
                            Limit  1
                            );

        -- Leave if a cost has been found, shortest routes will always be found first (apart from for SEA, then it needs to be calculated)
        IF (Select Min(cost) From tmp_src Where terrno in (Select terrno From tmp_final) and (sr_terrtype_from!='SEA' or calced=1)) > 0 THEN
            Select Min(cost) Into sr_distance From tmp_src Where terrno in (Select terrno From tmp_final);
            LEAVE dijkstra;
        END IF;
		-- Leave if looking for boomers and cost is up to 3
		IF sr_terrname_to='Boomer' and (Select cost From tmp_src Where terrno=current_node)>=3 THEN LEAVE dijkstra; END IF;

    END;
    END WHILE;
END IF;

-- Check for costs on calculated territories
IF (Select Min(cost) From tmp_src Where terrno in (Select terrno From tmp_final)) is not null THEN 
	Select Min(cost) Into sr_distance From tmp_src Where terrno in (Select terrno From tmp_final); 
ELSE 
	Set sr_distance=null;
END IF;

-- Add in flight costs for redeploys
Update tmp_src s Join tmp_rede r On s.terrno=r.terrno and sr_terrname_to='Fly' Set s.cost=1;

-- Check for retaliation
Select order_code Into sr_ret_userno From sp_orders Where gameno=sr_gameno and userno=sr_userno and ordername='MA_000_user';

IF @sr_debug!='N' THEN Select *, "Final distance table" From tmp_src; END IF;

-- Output distances from initial node
IF sr_terrname_to in ('ALL','March','Sail','Transport','Amphibious','Fly','Ground','Naval','Land','Sea','Aerial','Boomer') THEN
    Select *, Concat(sr_terrname_to,' from ',sr_terrname_from) As action
    From   tmp_src
    Where  cost is not null and
		  (Case
            When sr_terrname_to in ('All','Aerial','Fly') Then cost > 0
            When sr_terrname_to in ('March') Then cost > 0
                                                  and userno in (sr_userno, -10)
                                                  and Length(terrtype)=4
            When sr_terrname_to in ('Sail') Then cost > 0
                                                 and userno in (sr_userno, 0, -10)
                                                 and Length(terrtype)=3
            When sr_terrname_to in ('Transport','Amphibious') and Length(sr_terrtype_from)=4 Then cost = 1
                                                                                                  and userno=sr_userno
                                                                                                  and Length(terrtype)=3
                                                                                                  and minor > 0
            When sr_terrname_to in ('Transport') Then (Length(terrtype)=4 and cost=1 and userno in (sr_userno,-10))
                                                       or (terrtype='SEA' and userno in (sr_userno, 0, -10))
            When sr_terrname_to in ('Amphibious') Then (Length(terrtype)=4 and cost=1 and userno!=sr_userno)
                                                       or (terrtype='SEA' and userno in (sr_userno, 0))
            When sr_terrname_to in ('Ground') Then cost > 0
                                                   and userno != sr_userno
                                                   and Length(terrtype)=4
            When sr_terrname_to in ('Naval') Then cost > 0
                                                  and userno not in (sr_userno, 0)
                                                  and terrtype='SEA'
            When sr_terrname_to in ('Land') Then (cost = 1 and userno not in (0,sr_userno) and Length(terrtype)=4)
												 or (cost > 0 and userno in (0,sr_userno) and Length(terrtype)=3)
            When sr_terrname_to in ('Sea') Then (cost = 1 and userno not in (0,sr_userno) and Length(terrtype)=3)
												or (cost > 0 and userno=sr_userno and Length(terrtype)=4)
            When sr_terrname_to in ('Boomer') Then cost <= 2 and userno>-9
           End
           -- Add in redeployment options
           or (terrno in (Select terrno From tmp_rede)))
           -- Force retaliation options
           and (userno=Case
                        When Length(terrtype)=4 and sr_terrname_to in ('Sea') Then userno
                        When Length(terrtype)=3 and sr_terrname_to in ('Transport','Amphibious','Land','Fly') Then userno
                        Else Coalesce(sr_ret_userno,userno)
                       End
				or (sr_ret_userno is not null
				    and sr_terrname_to not in ('March','Fly','Sail','Transport','Sea','Land')
					and sr_homes=0
					and sr_strat_tech=5
                    and userno in (-9,-10)
                    and terrtype=sr_power_terrtype
                    )
				)
    Order By terrname
    ;
END IF;

DROP TABLE IF EXISTS tmp_src;
DROP TABLE IF EXISTS tmp_dest;
DROP TABLE IF EXISTS tmp_rede;

END sproc;
END;
$$
DELIMITER ;
