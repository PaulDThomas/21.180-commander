use asupcouk_asup;
Drop procedure if exists sr_4_attack_aerial;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_4_attack_aerial` (sr_gameno INT
                                               ,sr_powername VARCHAR(15)
                                               ,sr_terrname_from VARCHAR(25)
                                               ,sr_terrname_to VARCHAR(25)
                                               ,sr_major INT
                                               ,sr_minor INT
                                               ,sr_att_major CHAR(1)
                                               )
BEGIN
sproc:BEGIN

-- $Id: sr_4_attack_aerial.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_4_ATTACK_AERIAL";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_ma INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_terrno_from INT Default 0;
DECLARE sr_terrno_to INT Default 0;
DECLARE sr_major_from_before INT Default 0;
DECLARE sr_minor_from_before INT Default 0;
DECLARE sr_major_to_before INT Default 0;
DECLARE sr_minor_to_before INT Default 0;
DECLARE sr_major_to_after INT Default 0;
DECLARE sr_minor_to_after INT Default 0;
DECLARE mcost INT DEFAULT 0;
DECLARE ocost INT DEFAULT 0;
DECLARE gcost INT DEFAULT 0;
DECLARE sr_att_powername VARCHAR(15);
DECLARE sr_def_powername VARCHAR(15);
DECLARE sr_def_userno INT DEFAULT 0;
DECLARE sr_minerals INT DEFAULT 0;
DECLARE sr_oil INT DEFAULT 0;
DECLARE sr_grain INT DEFAULT 0;
DECLARE sr_tech INT DEFAULT 0;
DECLARE sr_strat_tech INT DEFAULT 0;
DECLARE sr_homes INT DEFAULT null;
DECLARE sr_power_terrtype VARCHAR(4) DEFAULT "";
DECLARE sr_attack_array TEXT;
DECLARE sr_result TEXT;
DECLARE sr_retaliation INT DEFAULT 0;
DECLARE sr_ret_userno INT;

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno < 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check powername
If sr_powername not in (Select powername From sp_resource r Where gameno=sr_gameno and dead='N') Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Power</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select userno, land_tech, minerals, oil, grain, strategic_tech
Into sr_userno, sr_tech, sr_minerals, sr_oil, sr_grain, sr_strat_tech
From sp_resource
Where gameno=sr_gameno and powername=sr_powername;
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

IF Upper(sr_terrname_from) = Upper(sr_terrname_to) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>No distance</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerrnameFrom",sr_terrname_from)
                   ,sf_fxml("TerrnameTo",sr_terrname_to)
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
                             and Length(terrtype)=4) Then
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

-- Check to territory and ownership
IF sr_terrname_to not in (Select terrname
                            From sp_places p, sp_board b
                            Where p.terrno=b.terrno
                             and b.gameno=sr_gameno
                             and b.userno!=sr_userno
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
                             and Length(terrtype)=4) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid To territory</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select terrno, powername, userno, major, minor
Into sr_terrno_to, sr_def_powername, sr_def_userno, sr_major_to_before, sr_minor_to_before 
From sv_map 
Where gameno=sr_gameno
 and terrname=sr_terrname_to
 and info=1
;

-- Check available resources
Select Ceil(fly_jm*sr_major+fly_nm*sr_minor)+1
       ,Ceil(fly_jo*sr_major+fly_no*sr_minor)+1
       ,Ceil(fly_jg*sr_major+fly_ng*sr_minor)+1
Into mcost, ocost, gcost
From sp_tech
Where tech_level=sr_tech
;
IF mcost > sr_minerals or ocost > sr_oil or gcost > sr_grain THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Not enough resource available to attack</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("TerritoryFrom",sr_terrname_from)
                   ,sf_fxml("TerritoryTo",sr_terrname_to)
                   ,sf_fxml("Major",sr_major)
                   ,sf_fxml("Minor",sr_minor)
                   ,sf_fxml("Minerals",sr_minerals)
                   ,sf_fxml("Oil",sr_oil)
                   ,sf_fxml("Grain",sr_grain)
                   ,sf_fxml("LandTech",sr_tech)
                   ,sf_fxml("MineralCost",mcost)
                   ,sf_fxml("OilCost",ocost)
                   ,sf_fxml("GrainCost",gcost)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Do not attack major unless specified
IF sr_att_major != 'Y' THEN
    Set sr_att_major = 'N';
END IF;

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat("You have aerially attacked ",sr_terrname_to
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
            ,Concat("You have been attacked aerially by ",sr_powername
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
call sr_4_attack_set(sr_gameno, 'Aerial', sr_def_powername, sr_terrname_to, sr_terrname_from);
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

-- Update territory from
call sr_take_territory(sr_gameno, sr_terrname_from, sr_powername, sr_major_from_before-sr_major, sr_minor_from_before-sr_minor);

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

-- Set old orders success
Insert into sp_old_orders (gameno, ordername, order_code)
 Values (sr_gameno, proc_name, Concat("<SUCCESS>"
                                     ,sf_fxml("Gameno",sr_gameno)
                                     ,sf_fxml("Powername",sr_powername)
                                     ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                     ,sf_fxml("TerritoryTo",sr_terrname_to)
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

-- Always move queue
Delete From sp_orders Where gameno=sr_gameno and userno=sr_userno and ordername in ('att_terr','def_terr','def_power','Action');
Update sp_orders Set order_code='Orders processed' 
Where gameno=sr_gameno 
 and userno=sr_userno 
 and turnno=sr_turnno 
 and phaseno=sr_phaseno 
 and (order_code like 'Waiting%' or order_code='Orders processing')
;
Call sr_move_queue(sr_gameno);

END sproc;
END
$$

Delimiter ;

/*
Call sr_take_territory(48,'Iran','Europe',1,5);
Call sr_take_territory(48,'Iberia','Europe',0,2);
Call sr_take_territory(48,'India','Africa',1,1);
Call sr_take_territory(48,'Burma','Neutral',0,0);
Update sp_resource Set minerals=1, oil=1, grain=1 Where gameno=48 and powername='Europe';
delete from sp_old_orders;
delete from sp_message_queue;

-- Check gameno
-- Call sr_4_attack_aerial (-1, 'Europe', 'Iran', 'India', 0, 5, 'Y');

-- Check powername
-- Call sr_4_attack_aerial (48, 'Dewsbury', 'Iran', 'India', 0, 5, 'Y');
-- Call sr_4_attack_aerial (48, 'China', 'Iran', 'India', 0, 5, 'Y');

-- Check from territory
-- Call sr_4_attack_aerial (48, 'Europe', 'Iranx', 'India', 0, 5, 'Y');
-- Call sr_4_attack_aerial (48, 'Europe', 'Bay of Bengal','India', 0, 5, 'Y');

-- Check troops available
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 10, 15, 'Y');
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 10, 5, 'Y');
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 0, 15, 'Y');

-- Check to territory
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'Halifax', 0, 5, 'Y');
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'Iberia', 0, 5, 'Y');

-- Check available resources
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 0, 5, 'Y');
Update sp_resource Set max_minerals=12, minerals=10, oil=20, grain=10, land_tech=3 Where gameno=48 and powername='Europe';
Update sp_resource Set max_minerals=12, minerals=10, oil=10, grain=10 Where gameno=48 and powername='Africa';

-- Actual attack
-- Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 0, 2, 'Y');
Call sr_4_attack_aerial (48, 'Europe', 'Iran', 'India', 1, 2, 'Y');
Call sr_take_territory(48, 'India', 'Europe', 0, 1);
Call sr_4_attack_aerial (48, 'Europe', 'India', 'Burma', 0, 1, 'Y');

select * from sp_message_queue;
-- select * from sv_map Where gameno=48 and terrname in ('Iran','India','Burma');
-- select * from sp_old_orders;
-- select * from sp_resource where gameno=48 and powername='Europe';
*/