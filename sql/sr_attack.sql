use asupcouk_asup;
Drop procedure if exists sr_attack;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_attack` (sr_gameno INT
											 ,sr_terrname VARCHAR(25)
											 ,sr_powername VARCHAR(15)
											 ,INOUT sr_attack_array TEXT
											 )
BEGIN
sproc:BEGIN

-- Input Parts of attack array are...
-- AttackTanks
-- AttackArmies
-- AttackBoomers
-- AttackNavies
-- AttackMajor
-- MaxRounds
-- Coastal

-- Output Parts of attack array are...
-- AttackTanks
-- AttackArmies
-- AttackBoomers
-- AttackNavies
-- DefendingPowername
-- AttackResult
-- TerritoryTanks
-- TerritoryArmies
-- TerritoryBoomers
-- TerritoryNavies

-- This procedure calls sr_attack_role to resolve conflicts
-- This procedure should only be called by the sr_4_att procedures which handle all territory / troop / resource changes

-- $Id: sr_attack.sql 287 2015-05-18 22:36:07Z paul $
DECLARE proc_name TEXT Default "SR_ATTACK";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_terrtype VARCHAR(4);
DECLARE sr_round INT Default 0;
DECLARE sr_max_rounds INT Default 999;
DECLARE sr_coastal CHAR(1) Default 'N';

DECLARE sr_att_userno INT Default 0;
DECLARE sr_att_powername VARCHAR(15);
DECLARE sr_att_tanks INT Default 0;
DECLARE sr_att_armies INT Default 0;
DECLARE sr_att_boomers INT Default 0;
DECLARE sr_att_navies INT Default 0;
DECLARE sr_att_tanks_init INT Default 0;
DECLARE sr_att_armies_init INT Default 0;
DECLARE sr_att_boomers_init INT Default 0;
DECLARE sr_att_navies_init INT Default 0;
DECLARE sr_att_attmaj TEXT Default 'N';
DECLARE sr_att_minerals INT Default 0;
DECLARE sr_att_oil INT Default 0;
DECLARE sr_att_grain INT Default 0;
DECLARE sr_att_lstars INT Default 0;
DECLARE sr_att_land_tech INT Default 0;
DECLARE sr_att_water_tech INT Default 0;
DECLARE sr_att_naughty TEXT Default 'N';

DECLARE sr_def_userno INT Default 0;
DECLARE sr_def_powername VARCHAR(15) Default 'Locals';
DECLARE sr_def_tanks INT Default 0;
DECLARE sr_def_armies INT Default 0;
DECLARE sr_def_boomers INT Default 0;
DECLARE sr_def_navies INT Default 0;
DECLARE sr_def_tanks_init INT Default 0;
DECLARE sr_def_armies_init INT Default 0;
DECLARE sr_def_boomers_init INT Default 0;
DECLARE sr_def_navies_init INT Default 0;
DECLARE sr_def_attmaj TEXT Default 'N';
DECLARE sr_def_minerals INT Default 1;
DECLARE sr_def_oil INT Default 1;
DECLARE sr_def_grain INT Default 1;
DECLARE sr_def_lstars INT Default 0;
DECLARE sr_def_land_tech INT Default 0;
DECLARE sr_def_water_tech INT Default 0;
DECLARE sr_defense TEXT Default 'Defend';
DECLARE sr_def_naughty TEXT Default 'N';

DECLARE sr_att_dice_base INT Default 1;
DECLARE sr_att_dice INT Default 1;
DECLARE sr_att_mod INT Default 0;
DECLARE sr_att_points INT Default 0;
DECLARE sr_def_dice_base INT Default 1;
DECLARE sr_def_dice INT Default 1;
DECLARE sr_def_mod INT Default 0;
DECLARE sr_def_points INT Default 0;
DECLARE sr_dice_roll INT Default 0;
DECLARE sr_messagexml TEXT;
DECLARE sr_messagexmlno_att INT Default 0;
DECLARE sr_messagexmlno_def INT Default 0;
DECLARE sr_att_dice_roll INT Default 0;
DECLARE sr_def_dice_roll INT Default 0;


-- Split up attacking string
Set sr_max_rounds = Least(ExtractValue(sr_attack_array, '//MaxRounds'),999);
Set sr_coastal = Case When ExtractValue(sr_attack_array, '//Coastal')!='' Then ExtractValue(sr_attack_array, '//Coastal') Else 'N' End;
Set sr_att_attmaj = Case When ExtractValue(sr_attack_array, '//AttackMajor')!='' Then ExtractValue(sr_attack_array, '//AttackMajor') Else 'N' End;
Set sr_att_tanks_init = ExtractValue(sr_attack_array, '//AttackTanks');
Set sr_att_armies_init = ExtractValue(sr_attack_array, '//AttackArmies');
Set sr_att_boomers_init = ExtractValue(sr_attack_array, '//AttackBoomers');
Set sr_att_navies_init = ExtractValue(sr_attack_array, '//AttackNavies');


-- Initial debug
IF @sr_debug!='N' THEN Select "Initial", sr_attack_array; END IF;

-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    Set sr_attack_array = 'FAIL';
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check attacking powername
IF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N') THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Power</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("AttackingPowername",sr_powername)
                   ,sf_fxml("DefendingPowername",sr_def_powername)
                   ,"</FAIL>")
            );
    Set sr_attack_array = 'FAIL';
    LEAVE sproc;
END IF;
-- Keep required values for attacking user
Select userno, minerals, oil, grain, lstars, land_tech, water_tech, naughty, powername
Into sr_att_userno, sr_att_minerals, sr_att_oil, sr_att_grain, sr_att_lstars, sr_att_land_tech, sr_att_water_tech, sr_att_naughty, sr_att_powername
From sp_resource
Where gameno=sr_gameno
 and powername=sr_powername
;
-- Check resources are available, unless attacking with only a boomer
IF Least(sr_att_minerals,sr_att_oil,sr_att_grain) < 1 and Least(sr_att_tanks_init,sr_att_armies_init,sr_att_navies_init) > 1
   THEN
    Insert into sp_old_orders (ordername, order_code, gameno, turnno, phaseno)
     Values (proc_name, Concat("<FAIL><Reason>Attacker has no resources</Reason>"
                              ,sf_fxml('Array',sr_attack_array)
                              ,"</FAIL>")
            ,sr_gameno, sr_turnno, sr_phaseno);
    Set sr_attack_array = 'FAIL';
    LEAVE sproc;
END IF;

-- Check defending territory
IF sr_terrname not in (Select terrname
                       From sp_places p, sp_board b
                       Where b.terrno=p.terrno
                        and b.gameno=sr_gameno
                        and b.userno != sr_att_userno
                        and p.terrtype != 'OCE') THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name, Concat("<FAIL><Reason>Invalid territory</Reason>"
                                                               ,sf_fxml("TerritoryName",sr_terrname)
                                                               ,"</FAIL>")
            );
    Set sr_attack_array = 'FAIL';
    LEAVE sproc;
END IF;
-- Get defensive parameters
Select userno, powername
 ,Case When Length(terrtype)=4 Then major Else 0 End, Case When Length(terrtype)=4 Then minor Else 0 End
 ,Case When Length(terrtype)=3 Then major Else 0 End, Case When Length(terrtype)=3 Then minor Else 0 End
 ,defense, attack_major, terrtype
Into sr_def_userno, sr_def_powername
 ,sr_def_tanks_init, sr_def_armies_init
 ,sr_def_boomers_init, sr_def_navies_init
 ,sr_defense, sr_def_attmaj, sr_terrtype
From sv_map
Where gameno=sr_gameno
 and terrname=sr_terrname
 and info=1
;
Select minerals, oil, grain, lstars, land_tech, water_tech, naughty
Into sr_def_minerals, sr_def_oil, sr_def_grain, sr_def_lstars, sr_def_land_tech, sr_def_water_tech, sr_def_naughty
From sp_resource
Where gameno=sr_gameno
 and userno=sr_def_userno
;

-- Always successfully clean up nukes and neutrons
-- You can not defend without any resources
-- You can not surrender to coastal attacks
Set sr_defense = Case When sr_def_powername='Nuked' or sr_def_powername like 'Neutron%' Then 'Surrender'
                      When sr_defense = 'Defend'
                          and (   sr_def_minerals=0
                               or sr_def_oil=0
                               or sr_def_grain=0
                               ) Then 'Resist'
                      When sr_defense = 'Surrender'
                          and sr_coastal = 'Y' Then 'Resist'
                      Else sr_defense
                      End;


-- Initial debug
IF @sr_debug!='N' THEN
    Select "Attacking string", sr_max_rounds, sr_att_attmaj, sr_att_tanks_init, sr_att_armies_init, sr_att_boomers_init, sr_att_navies_init, sr_att_naughty;
    Select "Defending", sr_defense, sr_def_powername, sr_def_minerals, sr_def_oil, sr_def_grain, sr_def_lstars, sr_def_land_tech, sr_def_water_tech, sr_def_naughty;
END IF;

-- Set initial variables
Select sr_att_tanks_init, sr_att_armies_init, sr_att_boomers_init, sr_att_navies_init
       ,sr_def_tanks_init, sr_def_armies_init, sr_def_boomers_init, sr_def_navies_init
Into   sr_att_tanks, sr_att_armies, sr_att_boomers, sr_att_navies
       ,sr_def_tanks, sr_def_armies, sr_def_boomers, sr_def_navies
;

-- Check something to do
IF sr_att_tanks_init+sr_att_armies_init+sr_att_boomers_init+sr_att_navies_init < 1
   or Least(sr_att_tanks_init,sr_att_armies_init,sr_att_boomers_init,sr_att_navies_init) < 0
   THEN
    Insert into sp_old_orders (ordername, order_code)
     Values (proc_name, Concat("<FAIL><Reason>Invalid attacking array</Reason>"
                              ,sr_attack_array
                              ,"</FAIL>")
            );
    Set sr_attack_array = 'FAIL';
    LEAVE sproc;
END IF;

-- Process surrenders first
IF sr_defense = 'Surrender' and Length(sr_terrtype)=4 THEN
    Set sr_attack_array = Concat(sf_fxml('AttackTanks',sr_def_tanks+sr_att_tanks)
                                ,sf_fxml('AttackArmies',sr_def_armies+sr_att_armies)
                                ,sf_fxml('AttackBoomers','0')
                                ,sf_fxml('AttackNavies',sr_att_navies)
                                ,sf_fxml('DefendingPowername',sr_def_powername)
                                ,sf_fxml('AttackResult','Surrender')
                                ,sf_fxml('TerritoryTanks',sr_def_tanks+sr_att_tanks)
                                ,sf_fxml('TerritoryArmies',sr_def_armies+sr_att_armies)
                                ,sf_fxml('TerritoryBoomers','0')
                                ,sf_fxml('TerritoryNavies','0')
                                );
    -- Add messages
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,sr_att_userno
           ,Concat('Your troops have moved into '
                  ,sr_terrname
                  ,Case
                    When sr_def_powername = 'Nuked' Then ' and cleaned up nuclear waste'
                    When sr_def_powername like 'Neutron%' Then ' and cleaned up neutron bombardment'
                    Else Concat(' and peacefully merged with the forces from ',sr_def_powername)
				   End
                  ,'.  You now have '
                  ,sf_format_troops(sr_terrtype,sr_def_tanks+sr_att_tanks,sr_def_armies+sr_att_armies)
                  ,' in the territory.'
                  )
           );
    IF sr_def_userno > 0 THEN
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,sr_def_userno
               ,Concat('Troops owned by '
                      ,sr_powername
                      ,' have moved into '
                      ,sr_terrname
                      ,' where your forces surrendered to them.  You lost'
                      ,sf_format_troops(sr_terrtype, sr_def_tanks, sr_def_armies)
                      ,'.'
                      )
               );
    END IF;
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,0
           ,Concat('Troops from '
                  ,sr_powername
                  ,' have moved into '
                  ,sr_terrname
                  ,Case
                    When sr_def_powername = 'Nuked' Then ' and cleaned up nuclear waste'
                    When sr_def_powername like 'Neutron%' Then ' and cleaned up neutron bombardment'
                    Else Concat(' and assumed control of those from ',sr_def_powername)
				   End
                  ,'.'
                  )
           );
    Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_def_tanks+sr_att_tanks, sr_def_armies+sr_att_armies);
    LEAVE sproc;
-- Process Sea surrender
ELSEIF sr_defense = 'Surrender' and Length(sr_terrtype)=3 THEN
    Set sr_attack_array = Concat(sf_fxml('AttackTanks','0')
                                ,sf_fxml('AttackArmies','0')
                                ,sf_fxml('AttackBoomers',sr_def_boomers+sr_att_boomers)
                                ,sf_fxml('AttackNavies',sr_def_navies+sr_att_navies)
                                ,sf_fxml('DefendingPowername',sr_def_powername)
                                ,sf_fxml('AttackResult','Surrender')
                                ,sf_fxml('TerritoryTanks','0')
                                ,sf_fxml('TerritoryArmies','0')
                                ,sf_fxml('TerritoryBoomers',sr_def_boomers+sr_att_boomers)
                                ,sf_fxml('TerritoryNavies',sr_def_navies+sr_att_navies)
                                );
    -- Add messages
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,sr_att_userno
           ,Concat('Your troops have moved into '
                  ,sr_terrname
                  ,Case
                    When sr_def_powername = 'Nuked' Then ' and cleaned up nuclear waste'
                    When sr_def_powername like 'Neutron%' Then ' and cleaned up neutron bombardment'
                    Else Concat(' and peacefully merged with the forces from ',sr_def_powername)
				   End
                  ,'.  You now have '
                  ,sf_format_troops(sr_terrtype,sr_def_boomers+sr_att_boomers,sr_def_navies+sr_att_navies)
                  ,' in the territory.'
                  )
           );
    IF sr_def_userno > 0 THEN
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,sr_def_userno
               ,Concat('Troops owned by '
                      ,sr_powername
                      ,' have moved into '
                      ,sr_terrname
                      ,' where your forces surrendered to them.  You lost'
                      ,sf_format_troops(sr_terrtype, sr_def_boomers, sr_def_navies)
                      ,'.'
                      )
               );
    END IF;
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,0
           ,Concat('Troops from '
                  ,sr_powername
                  ,' have moved into '
                  ,sr_terrname
                  ,Case
                    When sr_def_powername = 'Nuked' Then ' and cleaned up nuclear waste'
                    When sr_def_powername like 'Neutron%' Then ' and cleaned up neutron bombardment'
                    Else Concat(' and assumed control of those from ',sr_def_powername)
				   End
                  ,'.'
                  )
           );
    Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_def_boomers+sr_att_boomers, sr_def_navies+sr_att_navies);
    LEAVE sproc;
END IF;

IF @sr_debug!='N' THEN Select "Processed surrenders"; END IF;

-- Process militia on land
IF sr_def_tanks + sr_def_armies < 1 and Length(sr_terrtype) = 4 THEN
    Set sr_dice_roll = Ceiling(Rand()*6);
    Set sr_att_armies = Greatest(sr_att_armies-Floor(sr_dice_roll/3),0);
    Set sr_attack_array = Concat(sf_fxml('AttackTanks',sr_att_tanks)
                                ,sf_fxml('AttackArmies',sr_att_armies)
                                ,sf_fxml('AttackBoomers','0')
                                ,sf_fxml('AttackNavies',sr_att_navies)
                                ,sf_fxml('DefendingPowername',sr_def_powername)
                                );
    -- Victory
    IF sr_att_tanks + sr_att_armies > 0 THEN
        Set sr_attack_array = Concat(sr_attack_array
                                    ,sf_fxml('AttackResult','Victory')
                                    ,sf_fxml('TerritoryTanks',sr_att_tanks)
                                    ,sf_fxml('TerritoryArmies',sr_att_armies)
                                    ,sf_fxml('TerritoryBoomers','0')
                                    ,sf_fxml('TerritoryNavies','0')
                                    );
        -- Add messages
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,sr_att_userno
               ,Concat('You have moved '
                      ,sf_format_troops(sr_terrtype,sr_att_tanks_init,sr_att_armies_init)
                      ,' into '
                      ,sr_terrname
                      ,' and defeated militia controlled by '
                      ,sr_def_powername
                      ,'.  You now have '
                      ,sf_format_troops(sr_terrtype, sr_att_tanks, sr_att_armies)
                      ,' in the territory.'
                      )
               );
        IF sr_def_userno > 0 THEN
            Insert Into sp_message_queue (gameno, userno, message)
            Values (sr_gameno
                   ,sr_def_userno
                   ,Concat(sf_format_troops(sr_terrtype,sr_att_tanks_init,sr_att_armies)
                          ,' owned by '
                          ,sr_powername
                          ,' have moved into '
                          ,sr_terrname
                          ,' where your militia was defeated.'
                          )
                   );
        END IF;
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,0
               ,Concat('Troops from '
                      ,sr_powername
                      ,' have moved into '
                      ,sr_terrname
                      ,' and defeated militia controlled by '
                      ,sr_def_powername
                      ,'.'
                      )
               );
        -- Take territory
        Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_att_tanks, sr_att_armies);
    -- Defeat
    ELSE
        Set sr_attack_array = Concat(sr_attack_array
                                    ,sf_fxml('AttackResult','Defeat')
                                    ,sf_fxml('TerritoryTanks','0')
                                    ,sf_fxml('TerritoryArmies','0')
                                    ,sf_fxml('TerritoryBoomers','0')
                                    ,sf_fxml('TerritoryNavies','0')
                                    );
        -- Add messages
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,sr_att_userno
               ,Concat('You have moved '
                      ,sf_format_troops(sr_terrtype,sr_att_tanks_init,sr_att_armies_init)
                      ,' into '
                      ,sr_terrname
                      ,' and failed to defeat militia controlled by '
                      ,sr_def_powername
                      ,'.'
                      )
               );
        IF sr_def_userno > 0 THEN
            Insert Into sp_message_queue (gameno, userno, message)
            Values (sr_gameno
                   ,sr_def_userno
                   ,Concat(sf_format_troops(sr_terrtype, sr_att_tanks_init, sr_att_armies_init)
                          ,' owned by '
                          ,sr_powername
                          ,' have moved into '
                          ,sr_terrname
                          ,' where your militia successfully resisted the attack. '
                          )
                   );
        END IF;
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,0
               ,Concat('Troops from '
                      ,sr_powername
                      ,' have moved into '
                      ,sr_terrname
                      ,', militia controlled by '
                      ,sr_def_powername
                      ,' successfully stopped the invasion.'
                      )
               );
    END IF;
    LEAVE sproc;
-- Navies do not have to fight militia
ELSEIF sr_def_boomers + sr_def_navies < 1 and Length(sr_terrtype) = 3 THEN
    Set sr_attack_array = Concat(sf_fxml('AttackTanks','0')
                                ,sf_fxml('AttackArmies','0')
                                ,sf_fxml('AttackBoomers',sr_att_boomers)
                                ,sf_fxml('AttackNavies',sr_att_navies)
                                ,sf_fxml('AttackResult','Victory')
                                ,sf_fxml('TerritoryTanks','0')
                                ,sf_fxml('TerritoryArmies','0')
                                ,sf_fxml('TerritoryBoomers',sr_att_boomers)
                                ,sf_fxml('TerritoryNavies',sr_att_navies)
                                ,sf_fxml('DefendingPowername',sr_def_powername)
                                );
    -- Add messages
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,sr_att_userno
           ,Concat('You have moved '
                  ,sf_format_troops(sr_terrtype,sr_att_boomers_init,sr_att_navies_init)
                  ,' into '
                  ,sr_terrname
                  ,' and assumed control from '
                  ,sr_def_powername
                  ,'.'
                  )
           );
    IF sr_def_userno > 0 THEN
        Insert Into sp_message_queue (gameno, userno, message)
        Values (sr_gameno
               ,sr_def_userno
               ,Concat(sf_format_troops(sr_terrtype,sr_att_boomers_init,sr_att_navies_init)
                      ,' owned by '
                      ,sr_powername
                      ,' have moved into '
                      ,sr_terrname
                      ,' and assumed control of the territory.'
                      )
               );
    END IF;
    Insert Into sp_message_queue (gameno, userno, message)
    Values (sr_gameno
           ,0
           ,Concat('Troops from '
                  ,sr_powername
                  ,' have moved into '
                  ,sr_terrname
                  ,' and assumed control from '
                  ,sr_def_powername
                  ,'.'
                  )
           );
    -- Take territory
    Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_att_boomers, sr_att_navies);
    LEAVE sproc;
END IF;

IF @sr_debug!='N' THEN Select "Processed militia"; END IF;

-- ------------------------
-- Attack against forces
-- ------------------------

-- Check for existing battle report, or create one
Select messageno, message
Into   sr_messagexmlno_att, sr_messagexml
From   sp_message_queue
Where  gameno=sr_gameno
 and userno=sr_att_userno
 and ExtractValue(message,'/FIGHT/AttPowername') = sr_powername
 and ExtractValue(message,'/FIGHT/DefPowername') = sr_def_powername
 and ExtractValue(message,'/FIGHT/Terrname') = sr_terrname
;
Select messageno
Into   sr_messagexmlno_def
From   sp_message_queue
Where  gameno=sr_gameno
 and userno=sr_def_userno
 and ExtractValue(message,'/FIGHT/AttPowername') = sr_powername
 and ExtractValue(message,'/FIGHT/DefPowername') = sr_def_powername
 and ExtractValue(message,'/FIGHT/Terrname') = sr_terrname
;
IF sr_messagexmlno_att = 0 THEN
    Set sr_messagexml = Concat('<FIGHT>'
                              ,sf_fxml('AttPowername',sr_powername)
                              ,sf_fxml('DefPowername',sr_def_powername)
                              ,sf_fxml('Terrname',sr_terrname)
                              ,Case When sr_att_tanks_init > 0   Then sf_fxml('AttTanks',sr_att_tanks_init)     Else '' End
                              ,Case When sr_att_armies_init > 0  Then sf_fxml('AttArmies',sr_att_armies_init)   Else '' End
                              ,Case When sr_att_boomers_init > 0 Then sf_fxml('AttBoomers',sr_att_boomers_init) Else '' End
                              ,Case When sr_att_navies_init > 0  Then sf_fxml('AttNavies',sr_att_navies_init)   Else '' End
                              ,Case When sr_def_tanks_init > 0   Then sf_fxml('DefTanks',sr_def_tanks_init)     Else '' End
                              ,Case When sr_def_armies_init > 0  Then sf_fxml('DefArmies',sr_def_armies_init)   Else '' End
                              ,Case When sr_def_boomers_init > 0 Then sf_fxml('DefBoomers',sr_def_boomers_init) Else '' End
                              ,Case When sr_def_navies_init > 0  Then sf_fxml('DefNavies',sr_def_navies_init)   Else '' End
                              ,sf_fxml('Rounds','0')
                              ,sf_fxml('LStarDice','')
                              ,sf_fxml('TechDice','')
                              ,sf_fxml('DefAction','')
                              ,'</FIGHT>'
                              );
END IF;

-- Print debug info
IF @sr_debug!='N' THEN Select "Pre dice", sr_messagexml; END IF;

Set sr_round = ExtractValue(sr_messagexml,'/FIGHT/Rounds');

-- Calculate number of dice, and modifiers
-- No tanks if no oil
-- IF sr_att_oil = 0 and Length(sr_terrtype)=4 THEN -- if you are attacking, you must have had the resources to attack!
--    Set sr_att_tanks = 0;
-- ELSE
IF sr_def_oil = 0 and Length(sr_terrtype)=4 THEN
    Set sr_def_tanks = 0;
END IF;

-- Dice for the most lstars
IF sr_att_lstars > sr_def_lstars THEN
    Set sr_att_dice_base = sr_att_dice_base+1;
    Set sr_messagexml = UpdateXML(sr_messagexml,'/FIGHT/LStarDice',sf_fxml('LStarDice',sr_powername));
ELSEIF sr_def_lstars > sr_att_lstars THEN
    Set sr_def_dice_base = sr_def_dice_base+1;
    Set sr_messagexml = UpdateXML(sr_messagexml,'/FIGHT/LStarDice',sf_fxml('LStarDice',sr_def_powername));
END IF;

-- Dice for the highest tech level
IF Greatest(sr_att_land_tech*((sr_att_tanks_init+sr_att_armies_init)>0)
           ,sr_att_water_tech*((sr_att_boomers_init+sr_att_navies_init)>0))
   > Greatest(sr_def_land_tech*((sr_def_tanks_init+sr_def_armies_init)>0)
           ,sr_def_water_tech*((sr_def_boomers_init+sr_def_navies_init)>0))
   THEN
    Set sr_att_dice_base = sr_att_dice_base+1;
    Set sr_messagexml = UpdateXML(sr_messagexml,'/FIGHT/TechDice',sf_fxml('TechDice',sr_powername));
ELSEIF Greatest(sr_att_land_tech*((sr_att_tanks_init+sr_att_armies_init)>0)
               ,sr_att_water_tech*((sr_att_boomers_init+sr_att_navies_init)>0))
       < Greatest(sr_def_land_tech*((sr_def_tanks_init+sr_def_armies_init)>0)
               ,sr_def_water_tech*((sr_def_boomers_init+sr_def_navies_init)>0)) THEN
    Set sr_def_dice_base = sr_def_dice_base+1;
    Set sr_messagexml = UpdateXML(sr_messagexml,'/FIGHT/TechDice',sf_fxml('TechDice',sr_def_powername));
END IF;

-- Dice for defense
IF sr_defense = 'Defend' THEN
    Set sr_def_dice_base = sr_def_dice_base+1;
END IF;
Set sr_messagexml = UpdateXML(sr_messagexml, '/FIGHT/DefAction', sf_fxml('DefAction',sr_defense));

-- Print debug info
IF @sr_debug!='N' THEN Select "Pre loop", sr_messagexml; END IF;

-- Loop through rolls
WHILE (sr_round < sr_max_rounds
       and (Case
             When sr_coastal='Y' Then sr_att_tanks+sr_att_armies+sr_att_boomers+sr_att_navies > 0
             When Length(sr_terrtype)=4 Then sr_att_tanks+sr_att_armies > 0
             Else sr_att_boomers+sr_att_navies > 0
            End)
       and sr_def_tanks+sr_def_armies+sr_def_boomers+sr_def_navies > 0 ) DO

    -- Set round and calculate force sizes
    Set sr_round=sr_round+1;
    Set sr_att_points = sr_att_tanks*5+sr_att_armies+sr_att_boomers*6+sr_att_navies;
    Set sr_def_points = sr_def_tanks*5+sr_def_armies+sr_def_boomers*6+sr_def_navies;

    -- Attacker has biggest force
    IF sr_att_points > sr_def_points THEN
        Select sr_att_dice_base+1, Case When sr_att_tanks + sr_att_boomers > 0 Then Floor((sr_att_points-sr_def_points)/3) Else 0 End
               ,sr_def_dice_base, 0
        Into sr_att_dice, sr_att_mod, sr_def_dice, sr_def_mod
        ;
    -- Defender has biggest force
    ELSEIF sr_att_points <= sr_def_points THEN
        Select sr_att_dice_base, 0
               ,sr_def_dice_base+1, Case When sr_def_tanks + sr_def_boomers > 0 Then Floor((sr_def_points-sr_att_points)/3) Else 0 End
        Into sr_att_dice, sr_att_mod, sr_def_dice, sr_def_mod
        ;
    -- Forces are the same
    ELSE
        Select sr_att_dice_base, 0, sr_def_dice_base, 0
        Into sr_att_dice, sr_att_mod, sr_def_dice, sr_def_mod
        ;
    END IF;

    -- Check for naughty people
    IF sr_att_mod=0 and sr_att_naughty='Y' THEN
        Set sr_att_mod=-4;
    END IF;
    IF sr_def_mod=0 and sr_def_naughty='Y' THEN
        Set sr_def_mod=-4;
    END IF;


    -- Roll the dice!
    Call sr_attack_role (sr_att_dice, sr_att_mod, sr_att_attmaj, sr_def_tanks, sr_def_armies, sr_def_boomers, sr_def_navies, sr_att_dice_roll);
	IF not(sr_round=1 and sr_att_boomers=1 and sr_att_navies=0) THEN 
		-- Allow boomer sneak attacks
		Call sr_attack_role (sr_def_dice, sr_def_mod, sr_def_attmaj, sr_att_tanks, sr_att_armies, sr_att_boomers, sr_att_navies, sr_def_dice_roll);
	END IF;

    IF @sr_debug != 'N' THEN    
        Select "UpdateMessageXML";
    END IF;
    
    Set sr_messagexml = UpdateXML(sr_messagexml,'/FIGHT/Rounds'
                                 ,Concat('<Rounds>',sr_round,'</Rounds>'
                                         ,'<R Id="R',sr_round,'">'
                                         ,Concat(Case When sr_att_tanks_init > 0   Then sf_fxml('AttTanks',sr_att_tanks)     Else '' End
                                                ,Case When sr_att_armies_init > 0  Then sf_fxml('AttArmies',sr_att_armies)   Else '' End
                                                ,Case When sr_att_boomers_init > 0 Then sf_fxml('AttBoomers',sr_att_boomers) Else '' End
                                                ,Case When sr_att_navies_init > 0  Then sf_fxml('AttNavies',sr_att_navies)   Else '' End
                                                ,Case When sr_def_tanks_init > 0   Then sf_fxml('DefTanks',sr_def_tanks)     Else '' End
                                                ,Case When sr_def_armies_init > 0  Then sf_fxml('DefArmies',sr_def_armies)   Else '' End
                                                ,Case When sr_def_boomers_init > 0 Then sf_fxml('DefBoomers',sr_def_boomers) Else '' End
                                                ,Case When sr_def_navies_init > 0  Then sf_fxml('DefNavies',sr_def_navies)   Else '' End
                                                ,sf_fxml('AttRoll',sr_att_dice_roll)
                                                ,sf_fxml('DefRoll',sr_def_dice_roll)
                                                ,sf_fxml('AttDice',sr_att_dice)
                                                ,sf_fxml('DefDice',sr_def_dice)
                                                ,sf_fxml('AttMod',Greatest(0,sr_att_mod))
                                                ,sf_fxml('DefMod',Greatest(0,sr_def_mod))
                                                ,sf_fxml('AttPoints',sr_att_points)
                                                ,sf_fxml('DefPoints',sr_def_points)
                                                )
                                       ,'</R>')
                                 );

    IF @sr_debug != 'N' THEN    
        Select "UpdatedMessageXML";
    END IF;
    
END WHILE;

-- Print debug info
IF @sr_debug!='N' THEN Select "Post", sr_messagexml; END IF;

-- Insert battle report into the message queue
IF sr_messagexmlno_att > 0 THEN
    Update sp_message_queue Set message=sr_messagexml Where messageno=sr_messagexmlno_att;
ELSE
    Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, sr_att_userno, sr_messagexml);
END IF;
IF sr_messagexmlno_def > 0 THEN
    Update sp_message_queue Set message=sr_messagexml Where messageno=sr_messagexmlno_def;
ELSE
    Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, sr_def_userno, sr_messagexml);
END IF;


-- Update attack array
Set sr_attack_array = Concat(sf_fxml('AttackTanks',sr_att_tanks)
                            ,sf_fxml('AttackArmies',sr_att_armies)
                            ,sf_fxml('AttackBoomers',sr_att_boomers)
                            ,sf_fxml('AttackNavies',sr_att_navies)
                            ,sf_fxml('AttackResult','')
                            ,sf_fxml('TerritoryTanks',sr_def_tanks)
                            ,sf_fxml('TerritoryArmies',sr_def_armies)
                            ,sf_fxml('TerritoryBoomers',sr_def_boomers)
                            ,sf_fxml('TerritoryNavies',sr_def_navies)
                            ,sf_fxml('DefendingPowername',sr_def_powername)
                            ,sf_fxml('DefAction',sr_defense)
                            );


-- Report defeat
IF (Case
     When sr_coastal='Y' Then sr_att_tanks+sr_att_armies+sr_att_boomers+sr_att_navies
     When Length(sr_terrtype)=4 Then sr_att_tanks+sr_att_armies
     Else sr_att_boomers+sr_att_navies
    End) < 1 THEN
    Set sr_powername = sr_def_powername;
    Set sr_attack_array = UpdateXML(sr_attack_array,'//AttackResult',sf_fxml('AttackResult','Defeat'));
    IF Length(sr_terrtype)=4 THEN
        Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_def_tanks, sr_def_armies);
    ELSE
        Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_def_boomers, sr_def_navies);
    END IF;
-- Report Victory
ELSEIF sr_def_tanks+sr_def_armies+sr_def_boomers+sr_def_navies < 1 THEN
    Set sr_attack_array = UpdateXML(sr_attack_array,'//AttackResult',sf_fxml('AttackResult','Victory'));
    IF sr_coastal='Y' and Length(sr_terrtype)=4 THEN
        Call sr_take_territory(sr_gameno, sr_terrname, sr_def_powername, sr_def_tanks, sr_def_armies);
    ELSEIF sr_coastal='Y' THEN
        Call sr_take_territory(sr_gameno, sr_terrname, sr_def_powername, sr_def_boomers, sr_def_navies);
    ELSEIF Length(sr_terrtype)=4 THEN
        Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_att_tanks, sr_att_armies);
        Set sr_attack_array = UpdateXML(sr_attack_array,'TerritoryTanks',sf_fxml('TerritoryTanks',sr_att_tanks));
        Set sr_attack_array = UpdateXML(sr_attack_array,'TerritoryArmies',sf_fxml('TerritoryArmies',sr_att_armies));
    ELSE
        Call sr_take_territory(sr_gameno, sr_terrname, sr_powername, sr_att_boomers, sr_att_navies);
        Set sr_attack_array = UpdateXML(sr_attack_array,'TerritoryBoomers',sf_fxml('TerritoryBoomers',sr_att_boomers));
        Set sr_attack_array = UpdateXML(sr_attack_array,'TerritoryNavies',sf_fxml('TerritoryNavies',sr_att_navies));
    END IF;
-- Report stalemate
ELSE
    Set sr_attack_array = UpdateXML(sr_attack_array,'//AttackResult',sf_fxml('AttackResult','Fight'));
END IF;

IF @sr_debug!='N' THEN Select "Nearly done"; END IF;

-- Set old orders for successful run
Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
 Values (sr_gameno
        ,sr_turnno
        ,sr_phaseno
        ,proc_name
        ,Concat("<SUCCESS>"
               ,sf_fxml('AttackingPowername',sr_att_powername)
               ,sf_fxml('InitialAttackingTanks',sr_att_tanks_init)
               ,sf_fxml('InitialAttackingArmies',sr_att_armies_init)
               ,sf_fxml('InitialAttackingBoomers',sr_att_boomers_init)
               ,sf_fxml('InitialAttackingNavies',sr_att_navies_init)
               ,sf_fxml('LStarDice',ExtractValue(sr_messagexml,'/FIGHT/LStarDice'))
               ,sf_fxml('TechDice',ExtractValue(sr_messagexml,'/FIGHT/TechDice'))
               ,sf_fxml('DefAction',ExtractValue(sr_messagexml,'/FIGHT/DefAction'))
               ,sf_fxml('AttDiceBase',sr_att_dice_base)
               ,sf_fxml('DefDiceBase',sr_def_dice_base)
               ,sf_fxml('Rounds',sr_round)
               ,sf_fxml('Victorious',sr_powername)
               ,sf_fxml('InitialDefendingTanks',sr_def_tanks_init)
               ,sf_fxml('InitialDefendingArmies',sr_def_armies_init)
               ,sf_fxml('InitialDefendingBoomers',sr_def_boomers_init)
               ,sf_fxml('InitialDefendingNavies',sr_def_navies_init)
               ,sr_attack_array
               ,"</SUCCESS>")
        );

IF @sr_debug!='N' THEN Select "Done"; END IF;

-- /* */;
END sproc;
END
$$

Delimiter ;
