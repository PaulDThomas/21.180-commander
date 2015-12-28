use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_take_territory;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_take_territory` (sr_gameno INT, sr_terrname VARCHAR(25), sr_powername VARCHAR(15), sr_major INT, sr_minor INT)
BEGIN
sproc:BEGIN

-- $Id: sr_take_territory.sql 302 2015-09-29 19:11:29Z paul $
DECLARE proc_name TEXT Default "SR_TAKE_TERRITORY";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_terrno INT Default 0;
DECLARE sr_terrtype VARCHAR(4);
DECLARE sr_check_powername VARCHAR(15);
DECLARE sr_output_powername TEXT;
DECLARE sr_check_n INT Default 0;
DECLARE sr_sep TEXT;
DECLARE sr_previous_powername VARCHAR(15);
DECLARE sr_previous_userno INT;
DECLARE sr_previous_major INT;
DECLARE sr_previous_minor INT;
DECLARE sr_update_message INT Default 0;
DECLARE sr_flen INT Default 0;
DECLARE sr_cand INT Default 0;
DECLARE sr_elen INT Default 0;
DECLARE sr_cmessage TEXT;
DECLARE sr_nmessage TEXT;
DECLARE sr_max_resource INT Default 0;
DECLARE sr_boomers INT;
DECLARE sr_boomers_rem INT;

-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_TAKE_TERRITORY", Concat("<FAIL><Reason>Invalid Game</Reason><Gameno>",sr_gameno,"</Gameno></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check territory name
IF sr_terrname not in (Select terrname From sp_places) THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, "SR_TAKE_TERRITORY", Concat("<FAIL><Reason>Invalid territory</Reason><TerritoryName>",sr_terrname,"</TerritoryName></FAIL>"));
    LEAVE sproc;
END IF;
-- Get territory info, do not use SV_MAP as acquire could have reassigned a company
Select terrname, p.terrtype, p.terrno, Coalesce(Max(res_amount),0), major, minor
Into sr_terrname, sr_terrtype, sr_terrno, sr_max_resource, sr_previous_major, sr_previous_minor
From sp_board b
Left Join sp_places p On b.terrno=p.terrno
Left Join (
 Select terrno, res_name, res_amount From sp_res_cards rc
 Inner Join sp_cards c On c.gameno=sr_gameno and rc.cardno=c.cardno and Coalesce(c.userno,0) <> 0
 ) cx On cx.terrno=p.terrno
Where b.gameno=sr_gameno
 and terrname=sr_terrname
Group by 1,2,3
;

-- Check new troop numbers
IF sr_minor < 0 or sr_major < 0 THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_TAKE_TERRITORY", Concat("<FAIL>"
                                                   ,"<Reason>Invalid troops</Reason>"
                                                   ,"<Powername>",sr_powername,"</Powername>"
                                                   ,"<Major>",sr_major,"</Major>"
                                                   ,"<Minor>",sr_minor,"</Minor>"
                                                   ,"</FAIL>"
                                                   )
             );
    LEAVE sproc;
END IF;

-- Check for Neutral assignment for an active Superpower or 0,0 of neutral territory
Select Count(*), r.powername
Into   sr_check_n, sr_check_powername
From   sp_resource r, sp_places p, sp_powers pw, sp_board b
Where  b.terrno=sr_terrno
 and   p.terrno=b.terrno
 and   pw.terrtype=p.terrtype
 and   r.powername=pw.powername
 and   r.dead='N'
 and   r.gameno=sr_gameno
 and   r.gameno=b.gameno
;
IF @sr_debug='X' THEN Select "CHECK ASSIGN", sr_terrname, sr_powername, sr_major, sr_minor, sr_check_powername, sr_max_resource; END IF;
-- Assign Superpower to any no troop superpower territory
IF sr_major=0 and sr_minor=0 and sr_check_n > 0 and sr_powername not in ('Nuke','Neutron','Meteor') THEN
    IF @sr_debug!='N' THEN Select "Reassign powername for territory:", sr_terrname, sr_powername, sr_major, sr_minor, sr_check_powername, sr_max_resource; END IF;
    Set sr_powername = sr_check_powername;
-- Assign Superpower to any trooped superpower territory
ELSEIF Greatest(sr_major,sr_minor)>0 and sr_powername='Neutral' and sr_check_powername is not null THEN
    IF @sr_debug!='N' THEN Select "Reassign powername for territory:", sr_terrname, sr_powername, sr_major, sr_minor, sr_check_powername, sr_max_resource; END IF;
    Set sr_powername = sr_check_powername;
-- Assign neutral to any unoccupied (non-superpower) territory
ELSEIF Greatest(sr_major, sr_minor, sr_max_resource)=0 and sr_powername not in ('Neutral','Nuke','Neutron','Meteor')  THEN
    IF @sr_debug!='N' THEN Select "Reassign powername for territory to Neutral:", sr_terrname, sr_powername, sr_major, sr_minor, sr_check_powername, sr_max_resource; END IF;
    Set sr_powername = 'Neutral';
END IF;

-- Ensure that powername is right for neutral territories
IF sr_powername in ('Warlord', 'Pirate', 'Warlords', 'Pirates', 'Neutral', 'Locals') THEN
    IF sr_major+sr_minor=0 and sr_max_resource=0 THEN Set sr_powername='Neutral';
    ELSEIF Length(sr_terrtype)=4 THEN Set sr_powername='Warlord';
    ELSE Set sr_powername='Pirate';
    END IF;
END IF;

-- Check power name
IF sr_powername like 'Warlord' or sr_powername like 'Pirate' THEN
    Set sr_userno=-1;
    IF Length(sr_terrtype)=3 THEN Set sr_output_powername='Local Pirates have taken control of ';
    ELSE Set sr_output_powername='Local Warlords have taken control of ';
    END IF;
    Set sr_sep=' from ';
ELSEIF sr_powername like 'Neutral' THEN
    Set sr_userno=0;
    IF Length(sr_terrtype)=3 THEN Set sr_output_powername='Locals have taken control of ';
    ELSE Set sr_output_powername='Locals have taken control of ';
    END IF;
    Set sr_sep=' from ';
ELSEIF sr_powername like 'Neutron' THEN
    Set sr_userno=-10;
    Set sr_output_powername='Neutron bombardment destroyed ';
    Set sr_sep=' previously owned by ';
ELSEIF sr_powername like 'Meteor' THEN
    Set sr_userno=-9;
    Set sr_output_powername='The Meteor storm destroyed ';
    Set sr_sep=' previously owned by ';
ELSEIF sr_powername like 'Nuke' THEN
    Set sr_userno=-9;
    Set sr_output_powername='Nuclear waste destoyed ';
    Set sr_sep=' previously owned by ';
ELSEIF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N')  THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, "SR_TAKE_TERRITORY", Concat("<FAIL><Reason>Invalid powername</Reason>",sf_fxml('PowerName',sr_powername),"</FAIL>"));
    LEAVE sproc;
ELSE
    Set sr_userno=(Select userno From sp_resource Where gameno=sr_gameno and powername=sr_powername);
    Set sr_output_powername=(Select Concat(powername,' has taken control of ') From sp_resource Where gameno=sr_gameno and powername=sr_powername);
    Set sr_sep=' from ';
END IF;

-- Get current powername
Select Case When b.userno=-9 Then 'nuclear waste land'
            When b.userno=-10 Then 'neutron bombardment'
            When length(sr_terrtype)=3 and b.userno=-1 Then 'local Pirates'
            When b.userno=-1 Then 'local Warlords'
            When b.userno=0 Then 'locals'
        Else powername
        End
       ,b.userno
       ,Case When b.userno in (-9,-10) Then ' after cleaning up '
        Else sr_sep
        End
Into sr_previous_powername
     ,sr_previous_userno
     ,sr_sep
From sp_board b
Left Join sp_resource r
On b.gameno=r.gameno
 and b.userno=r.userno
Where b.gameno=sr_gameno
 and b.terrno=sr_terrno
;

-- Add previous troops when cleaning up neutron !!! NO - this should be done by the attack routine !!!
-- IF sr_previous_userno=-10 THEN
-- 	IF Length(sr_terrtype)=4 THEN Set sr_major = sr_major+sr_previous_major; END IF;
-- 	Set sr_minor = sr_minor+sr_previous_minor;
-- END IF;

-- Check/remove boomers
IF Length(sr_terrtype)=3 THEN
	-- Boomers are only for Superpowers
	IF sr_userno<=0 THEN Set sr_major=0; END IF;
	-- Remove any visible boomers that do not belong to the current user
	Delete From sp_boomers Where gameno=sr_gameno and terrno=sr_terrno and visible='Y' and userno!=sr_userno;
	-- Check number of visible boomers for userno (should only ever go down...
	Select Count(*) Into sr_boomers From sp_boomers Where gameno=sr_gameno and terrno=sr_terrno and visible='Y' and userno=sr_userno;
	IF sr_boomers > sr_major THEN 
		Set sr_boomers_rem=sr_boomers-sr_major;
		Delete From sp_boomers
		Where gameno=sr_gameno and userno=sr_userno and terrno=sr_terrno and visible='Y' 
		Order By rand()
		Limit sr_boomers_rem
		;
	ELSEIF sr_boomers < sr_major THEN
	    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
	    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
	            ,Concat("<FAIL><Reason>Not enough boomers</Reason>"
	                   ,sf_fxml("Powername",sr_powername)
	                   ,sf_fxml("Terrname",sr_terrname)
	                   ,sf_fxml("Boomers",sr_boomers)
					   ,sf_fxml("Major",sr_major)
	                   ,"</FAIL>")
	            );
	    LEAVE sproc;
	END IF;		
END IF;

-- Fail if no userno change
-- If sr_userno=sr_previous_userno Then
--    Insert into sp_old_orders (gameno, ordername, order_code)
--      Values (sr_gameno, "SR_TAKE_TERRITORY", Concat("<FAIL><Reason>Same user number</Reason>"
--                                                     ,"<NewPowername>",sr_powername,"</NewPowername>"
--                                                     ,"<NewUserno>",sr_userno,"</NewUserno>"
--                                                     ,"<Major>",sr_major,"</Major>"
--                                                     ,"<Minor>",sr_minor,"</Minor>"
--                                                     ,"<OldUserno>",sr_previous_userno,"</OldUserno>"
--                                                     ,"<OldPowername>",sr_previous_powername,"</OldPowername>"
--                                                     ,"</FAIL>"));
--     Leave sproc;
-- End If;

-- Change board
Update sp_board
Set    userno=sr_userno, major=sr_major, minor=sr_minor
Where  gameno=sr_gameno
 and   terrno=sr_terrno;
IF sr_previous_powername != sr_powername THEN
	Update sp_board
	Set    attack_major='No', defense='Defend', passuser=0
	Where  gameno=sr_gameno
	 and   terrno=sr_terrno;
END IF;

-- Change companies
Update sp_cards Set userno=Case When sr_userno=-9 Then 0 Else sr_userno End
Where gameno=sr_gameno
 and userno <> 0
 and cardno in (
                Select cardno
                From sp_res_cards
                Where terrno=sr_terrno
                )
 ;

-- Insert into old orders
Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
 Values (sr_gameno, sr_turnno, sr_phaseno, "SR_TAKE_TERRITORY", Concat("<SUCCESS>"
                                                                      ,sf_fxml("Territory",sr_terrname)
                                                                      ,sf_fxml("NewPowername",sr_powername)
                                                                      ,sf_fxml("NewUserno",sr_userno)
                                                                      ,sf_fxml("Major",sr_major)
                                                                      ,sf_fxml("Minor",sr_minor)
                                                                      ,sf_fxml("OldUserno",sr_previous_userno)
                                                                      ,sf_fxml("OldPowername",sr_previous_powername)
                                                                      ,"</SUCCESS>"));

-- Only produce message on user change
IF sr_userno != sr_previous_userno THEN
    -- Check if a power already has a message
    Select Count(*)
    Into sr_update_message
    From sp_message_queue
    Where message like Concat(sr_output_powername,"%",sr_sep,sr_previous_powername,"%")
     and gameno=sr_gameno;

    -- Inserting the territory name into the existing string
    If sr_update_message > 0 Then
        -- Get the lead in length
        Set sr_flen=Length(Concat(sr_output_powername))+1;
        -- Get the position of and or the powername
        Select message
               ,Locate(' from',message,sr_flen)
               ,Locate(' and ',message,sr_flen)
        Into sr_cmessage, sr_elen, sr_cand
        From sp_message_queue
        Where message like Concat(sr_output_powername,"%",sr_sep,sr_previous_powername,"%")
         and gameno=sr_gameno;

        -- Update the existing string, by inserting the new territory name
        Set sr_nmessage=Case When sr_cand > 0 Then Concat(Substring(sr_cmessage,1,sr_cand-1),', ',sr_terrname,Substring(sr_cmessage,sr_cand))
                           Else Concat(Substr(sr_cmessage,1,sr_flen-1),sr_terrname,' and ',Substring(sr_cmessage,sr_flen))
                           End;
        Update sp_message_queue
        Set message=sr_nmessage
        Where gameno=sr_gameno
         and message=sr_cmessage
        ;

    Else
        -- Create new message
        Set sr_nmessage=Concat(sr_output_powername
                              ,sr_terrname
                              ,sr_sep
                              ,sr_previous_powername
                              ,"."
                              );
        Insert Into sp_message_queue (gameno, userno, message, to_email)
        Values (sr_gameno, 0, sr_nmessage, 0);
    End If;
END IF;

/* */
END sproc;
END;
$$
Delimiter ;
