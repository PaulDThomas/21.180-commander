use asupcouk_asup;
Drop procedure if exists sr_4_attack_coastal;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_4_attack_coastal` (sr_gameno INT
                                                ,sr_powername VARCHAR(15)
                                                ,sr_terrname_from VARCHAR(25)
                                                ,sr_terrname_to VARCHAR(25)
                                                ,sr_terrname_bombard VARCHAR(25)
                                                ,sr_minor INT
                                                )
BEGIN
sproc:BEGIN

-- $Id: sr_4_attack_coastal.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_4_ATTACK_COASTAL";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_ma INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_att_powername VARCHAR(15);
DECLARE sr_att_dice INT DEFAULT 0;
DECLARE sr_att_minor INT DEFAULT 0;
DECLARE sr_minerals INT DEFAULT 0;
DECLARE sr_oil INT DEFAULT 0;
DECLARE sr_grain INT DEFAULT 0;
DECLARE sr_land_tech INT DEFAULT 0;
DECLARE sr_water_tech INT DEFAULT 0;
DECLARE sr_att_tech INT DEFAULT 0;
DECLARE sr_attack_array TEXT;

DECLARE sr_terrno_from INT DEFAULT 0;
DECLARE Sr_terrtype_from VARCHAR(4);
DECLARE sr_major_from_before INT DEFAULT 0;
DECLARE sr_minor_from_before INT DEFAULT 0;
DECLARE sr_major_from_after INT DEFAULT 0;
DECLARE sr_minor_from_after INT DEFAULT 0;

DECLARE sr_terrno_to INT DEFAULT 0;
DECLARE sr_terrtype_to CHAR(4);
DECLARE sr_major_to_before INT DEFAULT 0;
DECLARE sr_minor_to_before INT DEFAULT 0;
DECLARE sr_major_to_after INT DEFAULT 0;
DECLARE sr_minor_to_after INT DEFAULT 0;
DECLARE sr_minor_after INT DEFAULT 0;

DECLARE sr_terrno_bombard INT DEFAULT 0;
DECLARE sr_terrtype_bombard VARCHAR(4);
DECLARE sr_status_bombard TEXT;
DECLARE sr_major_bombard_before INT DEFAULT 0;
DECLARE sr_minor_bombard_before INT DEFAULT 0;
DECLARE sr_major_bombard_after INT DEFAULT 0;
DECLARE sr_minor_bombard_after INT DEFAULT 0;

DECLARE current_terrno INT DEFAULT 0;
DECLARE distance INT DEFAULT 0;
DECLARE mcost INT DEFAULT 0;
DECLARE ocost INT DEFAULT 0;
DECLARE gcost INT DEFAULT 0;

DECLARE sr_result TEXT;
DECLARE sr_retaliation INT DEFAULT 0;
DECLARE sr_ret_userno INT;

DECLARE sr_def_userno INT DEFAULT 0;
DECLARE sr_def_powername VARCHAR(15) DEFAULT 'locals';
DECLARE sr_def_minor INT DEFAULT 0;
-- DECLARE sr_def_tech INT DEFAULT 0;
-- DECLARE sr_def_lstars INT DEFAULT 0;
-- DECLARE sr_def_dice INT DEFAULT 0;
-- DECLARE sr_def_minerals INT DEFAULT 0;
-- DECLARE sr_def_oil INT DEFAULT 0;
-- DECLARE sr_def_grain INT DEFAULT 0;

-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check powername
IF Upper(sr_powername) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Power</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select userno, minerals, oil, grain, land_tech, water_tech
Into sr_userno, sr_minerals, sr_oil, sr_grain, sr_land_tech, sr_water_tech
From sp_resource
Where gameno=sr_gameno and powername=sr_powername
;
Set sr_att_powername = sr_powername;

-- Check right power is processing
IF sr_userno = (Select userno From sp_orders
                Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                      and ordername = 'MA_000'
                      and order_code like 'Waiting for retaliation%') THEN
    -- Set retaliation variables
    Select 1, order_code
    Into sr_retaliation, sr_ret_userno
    From sp_orders
    Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
          and ordername='MA_000_user'
    ;
ELSEIF sr_userno = (Select userno From sp_orders
                    Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                          and ordername='ORDSTAT'
                          and order_code in ('Orders processed','Orders processing','Waiting for orders')
                     )
        and 0 = (Select Count(*) From sp_orders
                 Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                       and ordername='MA_000'
                       and order_code like 'Waiting for retaliation%') THEN
    -- Normal attack
    Set sr_retaliation=0;
ELSE
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Invalid power to process</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check some movement
IF sr_minor < 1 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>No troops</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Minor",sr_minor)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Check from territory and ownership
IF sr_terrname_from not in (Select terrname
                            From sp_places p, sp_board b
                            Where p.terrno=b.terrno
                             and b.gameno=sr_gameno
                             and b.userno=sr_userno) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Invalid From Territory</Reason>"
                  ,sf_fxml("Gameno",sr_gameno)
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("TerritoryFrom",sr_terrname_from)
                  ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
-- Get info about from territory
Select terrno, terrtype Into sr_terrno_from, sr_terrtype_from From sp_places Where terrname=sr_terrname_from;
Select major, minor
Into   sr_major_from_before, sr_minor_from_before
From   sp_board
Where  gameno=sr_gameno
 and terrno=sr_terrno_from
;
Set sr_att_tech = Case When Length(sr_terrtype_from)=4 Then sr_land_tech Else sr_water_tech End;

-- Check bombard territory and ownership
IF sr_terrname_bombard not in (Select terrname
                               From sp_places p, sp_board b
                               Where p.terrno=b.terrno
                                and b.gameno=sr_gameno
                                and b.userno != sr_userno
                                and b.userno = Coalesce(sr_ret_userno, b.userno)
                                and Length(p.terrtype)!=Length(sr_terrtype_from)) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Bombard Territory</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("TerritoryBombard",sr_terrname_bombard)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
-- Get info about to territory
Select terrno, terrtype Into sr_terrno_bombard, sr_terrtype_bombard From sp_places Where terrname=sr_terrname_bombard;
-- Get defensive user information
Select powername, b.userno, major, minor
Into sr_def_powername, sr_def_userno, sr_major_bombard_before, sr_minor_bombard_before
From sp_board b
Left Join sp_resource r On b.userno=r.userno and b.gameno=r.gameno
Where b.gameno=sr_gameno and terrno=sr_terrno_bombard
;
Set sr_def_minor = sr_minor_bombard_before;
-- Check there is something to kill
IF sr_minor_bombard_before < 1 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Nothing to bombard</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("TerritoryBombard",sr_terrname_bombard)
                   ,sf_fxml("BombardMinor",sr_minor_bombard_before)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;


-- Check forces are available
IF sr_minor > sr_minor_from_before THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Not enough forces available to move</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryFromMajor",sr_major_from_before)
                   ,sf_fxml("TerritoryFromMinor",sr_minor_from_before)
                   ,sf_fxml("Minor",sr_minor)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Distance Algorithm
Call sr_distance(sr_gameno, sr_powername, sr_terrname_from, sr_terrname_to, distance);

IF distance is null THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>No way to Territory</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("Distance",distance)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select terrno, terrtype Into sr_terrno_to, sr_terrtype_to From sp_places Where terrname = sr_terrname_to;
Select major, minor Into sr_major_to_before, sr_minor_to_before From sp_board Where gameno=sr_gameno and terrno=sr_terrno_to;

-- Check bombard territory is next to to territory
IF 1 != (Select Count(*) From sp_border Where terrno_from=sr_terrno_to and terrno_to=sr_terrno_bombard) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>To and bombard territories are not next to each other</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("TerritoryBombard",sr_terrname_bombard)
                   ,"</FAIL>")
            );
    Leave sproc;
END IF;

-- Check available resources, no need to remove distance for attack
IF Length(sr_terrtype_from)=4 THEN
    Select Ceil(march_nm*sr_minor*distance)
           ,Ceil(march_no*sr_minor*distance)
           ,Ceil(march_ng*sr_minor*distance)
    Into mcost, ocost, gcost
    From sp_tech
    Where tech_level=sr_att_tech
    ;
ELSE
    Select Ceil(sail_nm*sr_minor*distance)
           ,Ceil(sail_no*sr_minor*distance)
           ,Ceil(sail_ng*sr_minor*distance)
    Into mcost, ocost, gcost
    From sp_tech
    Where tech_level=sr_att_tech
    ;
END IF;
-- Add resources for attack
Select mcost+1, ocost+1, gcost+1 Into mcost, ocost, gcost;
-- Check resources
IF mcost > sr_minerals or ocost > sr_oil or gcost > sr_grain THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Not enough resource available to move and attack</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("TerritoryBombard",sr_terrname_bombard)
                   ,sf_fxml("Distance",distance)
                   ,sf_fxml("Minor",sr_minor)
                   ,sf_fxml("Minerals",sr_minerals)
                   ,sf_fxml("Oil",sr_oil)
                   ,sf_fxml("Grain",sr_grain)
                   ,sf_fxml("Tech",sr_att_tech)
                   ,sf_fxml("MineralCost",mcost)
                   ,sf_fxml("OilCost",ocost)
                   ,sf_fxml("GrainCost",gcost)
                   ,"</FAIL>")
            );
    Leave sproc;
End If;

-- Update territory from if it is different from the territory to
IF sr_terrname_from != sr_terrname_to THEN
    Call sr_take_territory(sr_gameno, sr_terrname_from, sr_powername, sr_major_from_before, sr_minor_from_before-sr_minor);
END IF;

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat("You have attacked ",sr_terrname_bombard
               ," using ",sf_format_troops(sr_terrtype_from, 0, sr_minor)
               ," from ",sr_terrname_from
               ,Case When sr_terrname_from != sr_terrname_to Then Concat(" which moved to ",sr_terrname_to) Else "" End
               ," costing "
               ,Case When mcost=0 Then '' When mcost=1 Then '1 mineral, ' Else Concat(mcost,' minerals, ') End
               ,Case When ocost=0 Then '' Else Concat(ocost,' oil') End
               ,Case When ocost > 0 and gcost > 0 Then ' and ' Else '' End
               ,Case When gcost=0 Then '' Else Concat(gcost,' grain') End
               ,"."
               )
        );
-- Attacked message
IF sr_def_userno > 0 THEN
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_def_userno, -1
            ,Concat("You have been attacked by ",sr_powername
                   ," in ",sr_terrname_bombard
                   ," using ",sf_format_troops(sr_terrtype_from, 0, sr_minor)
                   ," from ",sr_terrname_from
                   ,Case When sr_terrname_from != sr_terrname_to Then Concat(" which moved to ",sr_terrname_to) Else "" End
                   ,"."
                   )
            );
END IF;
-- General message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, 0
        ,Concat(sr_powername
               ," has attacked ",sr_terrname_bombard
               ," with troops from ",sr_terrname_from
               ,Case When sr_terrname_from != sr_terrname_to Then Concat(" which moved to ",sr_terrname_to) Else "" End
               ,"."));

-- FIGHT!
Call sr_4_attack_set(sr_gameno, Case When Length(sr_terrtype_bombard)=4 Then 'Land' Else 'Sea' End, sr_def_powername, sr_terrname_bombard, Case When sr_terrname_from=sr_terrname_to Then sr_terrname_from Else null End);
Set sr_attack_array = Concat(sf_fxml('AttackTanks',0)
                            ,sf_fxml('AttackArmies',Case When Length(sr_terrtype_bombard)=3 Then sr_minor Else 0 End)
                            ,sf_fxml('AttackBoomers',0)
                            ,sf_fxml('AttackNavies',Case When Length(sr_terrtype_bombard)=4 Then sr_minor Else 0 End)
                            ,sf_fxml('AttackMajor','N')
                            ,sf_fxml('MaxRounds',99)
                            ,sf_fxml('Coastal','Y')
                            );
Call sr_attack(sr_gameno, sr_terrname_bombard, sr_att_powername, sr_attack_array);

Set sr_minor_after = Case
                      When Length(sr_terrtype_bombard)=4 Then ExtractValue(sr_attack_array,'//AttackNavies')
                      Else ExtractValue(sr_attack_array,'//AttackArmies')
                     End;

-- Update resources
Update sp_resource
Set minerals=minerals-mcost
 ,oil=oil-ocost
 ,grain=grain-gcost
Where gameno=sr_gameno
 and powername=sr_powername
;

-- Remove defenders resources if necessary
IF ExtractValue(sr_attack_array, '//DefAction') = 'Defend' THEN
    Update sp_resource
    Set minerals=minerals-1, oil=oil-1, grain=grain-1
    Where gameno=sr_gameno
     and powername=sr_def_powername
    ;
END IF;

-- Update attacking territory
IF sr_terrname_from = sr_terrname_to THEN
    Call sr_take_territory(sr_gameno, sr_terrname_to, sr_powername, sr_major_to_before, sr_minor_to_before-sr_minor+sr_minor_after);
ELSE
    Call sr_take_territory(sr_gameno, sr_terrname_to, sr_powername, sr_major_to_before, sr_minor_to_before+sr_minor_after);
END IF;

-- Get new values
Select major, minor Into sr_major_to_after, sr_minor_to_after From sp_board Where gameno=sr_gameno and terrno=sr_terrno_to;
Select major, minor Into sr_major_bombard_after, sr_minor_bombard_after From sp_board Where gameno=sr_gameno and terrno=sr_terrno_bombard;

-- Set old orders success
Insert into sp_old_orders (gameno, ordername, order_code)
 Values (sr_gameno, proc_name, Concat("<SUCCESS>"
                                     ,sf_fxml("Gameno",sr_gameno)
                                     ,sf_fxml("Powername",sr_powername)
                                     ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                     ,sf_fxml("TerritoryTo",sr_terrname_to)
                                     ,sf_fxml("TerritoryBombard",sr_terrname_bombard)
                                     ,sf_fxml("Distance",distance)
                                     ,sf_fxml("Minor",sr_minor)
                                     ,sf_fxml("MineralCost",mcost)
                                     ,sf_fxml("OilCost",ocost)
                                     ,sf_fxml("GrainCost",gcost)
                                     ,sf_fxml("Tech",sr_att_tech)
                                     ,"</SUCCESS>")
        );

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat(sr_terrname_to," is now guarded by "
               ,sf_format_troops(sr_terrtype_from,sr_major_to_after,sr_minor_to_after)
               ," and ",sr_terrname_bombard," is now guarded by "
               ,sf_format_troops(sr_terrtype_bombard,sr_major_bombard_after,sr_minor_bombard_after)
               ,"."
               )
        );
-- Attacked message
IF sr_def_userno > 0 THEN
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_def_userno, -1
            ,Concat(sr_terrname_to," is now guarded by "
                   ,sf_format_troops(sr_terrtype_from,sr_major_to_after,sr_minor_to_after)
                   ," and ",sr_terrname_bombard," is now guarded by "
                   ,sf_format_troops(sr_terrtype_bombard,sr_major_bombard_after,sr_minor_bombard_after)
                   ,"."
                   )
            );
END IF;

-- Always move queue, at the moment
Delete From sp_orders Where gameno=sr_gameno and userno=sr_userno and ordername in ('att_terr','def_terr','def_power','Action');
Update sp_orders Set order_code='Orders processed'
Where gameno=sr_gameno
 and userno=sr_userno
 and turnno=sr_turnno
 and phaseno=sr_phaseno
 and (order_code like 'Waiting%' or order_code='Orders processing')
;
Call sr_move_queue(sr_gameno);

-- /* */
END sproc;
END
$$

Delimiter ;
/*
Set @sr_debug='N';

call sr_move_queue(103);
update sp_game set deadline_uts=unix_timestamp()-1000;
call sr_move_queue(103);

select * from sp_orders where gameno=103 order by userno, phaseno;
Set @sr_debug='Y';


call sr_4_attack_coastal(103, 'Russia', 'Shark Bay', 'Timor Sea', 'Eastern Australia', 1);

select * from sp_orders where gameno=103 order by phaseno, userno;
select * from sp_orders where gameno=0;
*/
