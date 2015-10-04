use asupcouk_asup;
Drop procedure if exists sr_4_attack_land;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_4_attack_land` (sr_gameno INT
                                                    ,sr_powername TEXT
                                                    ,sr_terrname_from TEXT
                                                    ,sr_terrname_to TEXT
                                                    ,sr_major INT
                                                    ,sr_minor INT
                                                    ,sr_att_major CHAR(1)
                                                    )
BEGIN
sproc:BEGIN

-- $Id: sr_4_attack_land.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_4_ATTACK_LAND";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_def_userno INT Default 0;
DECLARE sr_def_powername Text;
DECLARE sr_att_powername Text;
DECLARE sr_terrno_from INT Default 0;
DECLARE sr_terrno_to INT Default 0;
DECLARE sr_major_from_before INT Default 0;
DECLARE sr_minor_from_before INT Default 0;
DECLARE sr_major_from_after INT Default 0;
DECLARE sr_minor_from_after INT Default 0;
DECLARE sr_major_to_before INT Default 0;
DECLARE sr_minor_to_before INT Default 0;
DECLARE sr_major_to_after INT Default 0;
DECLARE sr_minor_to_after INT Default 0;
DECLARE current_terrno INT DEFAULT 0;
DECLARE distance INT DEFAULT 0;
DECLARE mcost INT DEFAULT 0;
DECLARE ocost INT DEFAULT 0;
DECLARE gcost INT DEFAULT 0;
DECLARE sr_minerals INT DEFAULT 0;
DECLARE sr_oil INT DEFAULT 0;
DECLARE sr_grain INT DEFAULT 0;
DECLARE sr_attack_array TEXT;
DECLARE sr_tech INT DEFAULT 0;
DECLARE sr_strat_tech INT DEFAULT 0;
DECLARE sr_homes INT DEFAULT null;
DECLARE sr_power_terrtype TEXT DEFAULT "";
DECLARE sr_result TEXT;
DECLARE sr_retaliation INT DEFAULT 0;
DECLARE sr_ret_userno INT;
DECLARE sr_ma INT DEFAULT 0;

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
Select userno, minerals, oil, grain, land_tech, strategic_tech
Into sr_userno, sr_minerals, sr_oil, sr_grain, sr_tech, sr_strat_tech
From sp_resource
Where gameno=sr_gameno and powername=sr_powername
;
Set sr_att_powername = sr_powername;
Select terrtype Into sr_power_terrtype From sp_powers Where powername=sr_powername;
Select Count(*)>0 Into sr_homes From sv_map Where userno=sr_userno and gameno=sr_gameno and home_territory='Home' and info=1;

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
                          and order_code in ('Orders processed','Waiting for orders')
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
IF (sr_major < 1 and sr_minor < 1) or sr_minor < 0 or sr_major < 0 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>No troops</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Major",sr_major)
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
                             and b.userno=sr_userno
                             and Length(p.terrtype)=4) THEN
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
Select terrno Into sr_terrno_from From sp_places Where terrname=sr_terrname_from;
Select major, minor
Into   sr_major_from_before, sr_minor_from_before
From   sp_board
Where  gameno=sr_gameno
 and terrno=sr_terrno_from
;

IF @sr_debug='Y' THEN
Select terrname, sr_ret_userno, sr_gameno, sr_userno, sr_strat_tech
From sp_places p, sp_board b
Where p.terrno=b.terrno
 and b.gameno=sr_gameno
 and b.userno != sr_userno
 and b.userno = Coalesce(sr_ret_userno, b.userno)
 and (b.userno > -9 or sr_strat_tech=5 or (b.userno=-10 and b.passuser=sr_userno))
 and Length(p.terrtype)=4
Order by 1
;
END IF;

-- Check to territory and ownership
IF sr_terrname_to not in (Select terrname
                          From sp_places p, sp_board b
                          Where p.terrno=b.terrno
                           and b.gameno=sr_gameno
                           and b.userno != sr_userno
                           and (b.userno = Coalesce(sr_ret_userno, b.userno)
								or (sr_ret_userno is not null
									and sr_terrname_to not in ('March','Fly','Sail','Transport','Sea','Land')
									and sr_homes=0
									and sr_strat_tech=5
									and userno in (-9,-10)
									and terrtype=sr_power_terrtype
									)
								)
                           and (b.userno > -9 or sr_strat_tech=5 or (b.userno=-10 and b.passuser=sr_userno))
                           and Length(p.terrtype)=4) Then
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid To Territory</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,"</FAIL>")
            );
    Leave sproc;
End If;
-- Get info about to territory
Select terrno, powername, userno, major, minor
Into sr_terrno_to, sr_def_powername, sr_def_userno, sr_major_to_before, sr_minor_to_before
From sv_map
Where gameno=sr_gameno
 and terrname=sr_terrname_to
 and info=1
;


-- Check forces are available
IF sr_major > sr_major_from_before or sr_minor > sr_minor_from_before THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Not enough forces available to move</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryFromMajor",sr_major_from_before)
                   ,sf_fxml("TerritoryFromMinor",sr_minor_from_before)
                   ,sf_fxml("Major",sr_major)
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
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Check available resources
Set distance = distance-1;  -- Lower distance for attacking
Select Ceil(march_nm*sr_minor*distance+march_jm*sr_major*distance)
       ,Ceil(march_no*sr_minor*distance+march_jo*sr_major*distance)
       ,Ceil(march_ng*sr_minor*distance+march_jg*sr_major*distance)
Into mcost, ocost, gcost
From sp_tech
Where tech_level=sr_tech
;
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
                   ,sf_fxml("Distance",distance)
                   ,sf_fxml("Tanks",sr_major)
                   ,sf_fxml("Armies",sr_minor)
                   ,sf_fxml("Minerals",sr_minerals)
                   ,sf_fxml("Oil",sr_oil)
                   ,sf_fxml("Grain",sr_grain)
                   ,sf_fxml("LandTech",sr_tech)
                   ,sf_fxml("MineralCost",mcost)
                   ,sf_fxml("OilCost",ocost)
                   ,sf_fxml("GrainCost",gcost)
                   ,"</FAIL>")
            );
    Leave sproc;
End If;

-- Do not attack major unless specified
IF sr_att_major != 'Y' THEN
    Set sr_att_major = 'N';
END IF;

-- Update territory from
call sr_take_territory(sr_gameno, sr_terrname_from, sr_powername, sr_major_from_before-sr_major, sr_minor_from_before-sr_minor);

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat("You have attacked ",sr_terrname_to
               ," using ",sf_format_troops("LAND", sr_major, sr_minor)
               ," from ",sr_terrname_from
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
                   ," in ",sr_terrname_to
                   ," using ",sf_format_troops("LAND", sr_major, sr_minor)
                   ," from ",sr_terrname_from
                   ,"."
                   )
            );
END IF;
-- General message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, 0
        ,Concat(sr_powername
               ," has attacked ",sr_terrname_to
               ," with troops from ",sr_terrname_from
               ,"."));

-- Add redeploys and retaliations
Call sr_4_attack_set(sr_gameno, "Ground", sr_def_powername, sr_terrname_to, sr_terrname_from);
-- FIGHT!
Set sr_attack_array = Concat(sf_fxml('MaxRounds',999),sf_fxml('AttackTanks',sr_major),sf_fxml('AttackArmies',sr_minor),sf_fxml('AttackMajor',sr_att_major));
Call sr_attack(sr_gameno, sr_terrname_to, sr_powername, sr_attack_array);

-- Get number of troops returned
Select ExtractValue(sr_attack_array,'//TerritoryTanks')
       ,ExtractValue(sr_attack_array, '//TerritoryArmies')
       ,ExtractValue(sr_attack_array, '//AttackResult')
Into sr_major_to_after
     ,sr_minor_to_after
     ,sr_result
;

IF @sr_debug='Y' THEN Select sr_major_to_after, sr_minor_to_after, sr_result, sr_attack_array; END IF;

-- Update attackers resources
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

-- Set old orders success
Insert into sp_old_orders (gameno, ordername, order_code)
 Values (sr_gameno, proc_name, Concat("<SUCCESS>"
                                     ,sf_fxml("Gameno",sr_gameno)
                                     ,sf_fxml("Powername",sr_powername)
                                     ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                     ,sf_fxml("TerritoryTo",sr_terrname_to)
                                     ,sf_fxml("Distance",distance)
                                     ,sf_fxml("Major",sr_major)
                                     ,sf_fxml("Minor",sr_minor)
                                     ,sf_fxml("MineralCost",mcost)
                                     ,sf_fxml("OilCost",ocost)
                                     ,sf_fxml("GrainCost",gcost)
                                     ,sf_fxml("LandTech",sr_tech)
                                     ,"</SUCCESS>")
        );

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat(Case
                 When sr_result='Surrender' and (sr_def_powername='Nuked' or sr_def_powername like 'Neutron%') Then ""
                 When sr_result='Surrender' Then Concat("Your forces were surrendered to by ",sr_def_powername,". ")
                 When sr_result='Victory' Then Concat("Your forces were victorious against ",sr_def_powername,". ")
                 Else Concat("You were defeated by ",sr_def_powername,". ")
                End
               ,sr_terrname_to," is now guarded by "
               ,sf_format_troops("LAND",sr_major_to_after,sr_minor_to_after)
               ,"."
               )
        );
-- Attacked message
IF sr_def_userno > 0 THEN
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_def_userno, -1
            ,Concat(Case When sr_result='Defeat' and sr_major_to_after=0 and sr_minor_to_after=0 Then "Your forces were wiped out defending the territory. "
                         When sr_result='Defeat' Then "Your forces were victorious. "
                         When sr_result='Surrender' Then "Your forces surrendered. "
                         Else "You were defeated. "
                         End
                   ,sr_terrname_to," is now guarded by "
                   ,sf_format_troops("LAND",sr_major_to_after,sr_minor_to_after)
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