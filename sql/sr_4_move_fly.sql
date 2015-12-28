use asupcouk_asup;
Drop procedure if exists sr_4_move_fly;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_4_move_fly` (sr_gameno INT, sr_powername VARCHAR(15), sr_terrname_from VARCHAR(25), sr_terrname_to VARCHAR(25), sr_major INT, sr_minor INT)
BEGIN
sproc:BEGIN

-- $Id: sr_4_move_fly.sql 323 2015-12-19 21:25:27Z paul $
DECLARE proc_name TEXT Default "SR_4_MOVE_FLY";
DECLARE sr_userno INT Default 0;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_terrno_from INT Default 0;
DECLARE sr_terrno_to INT Default 0;
DECLARE sr_major_from_before INT Default 0;
DECLARE sr_minor_from_before INT Default 0;
DECLARE sr_major_to_before INT Default 0;
DECLARE sr_minor_to_before INT Default 0;
DECLARE done INT DEFAULT 0;
DECLARE checkterr TEXT Default "";
DECLARE mcost INT DEFAULT 0;
DECLARE ocost INT DEFAULT 0;
DECLARE gcost INT DEFAULT 0;
DECLARE sr_minerals INT DEFAULT 0;
DECLARE sr_oil INT DEFAULT 0;
DECLARE sr_grain INT DEFAULT 0;
DECLARE sr_tech INT DEFAULT 0;
DECLARE sr_userno_to_before INT DEFAULT 0;
DECLARE sr_major_to_after INT DEFAULT 0;
DECLARE sr_minor_to_after INT DEFAULT 0;

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
If Upper(sr_powername) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Power</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
Select userno, land_tech, minerals, oil, grain Into sr_userno, sr_tech, sr_minerals, sr_oil, sr_grain From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Check right power is processing
IF sr_userno != (Select userno From sp_orders
                 Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                       and (   (ordername='ORDSTAT'
                                and order_code in ('Orders processed','Waiting for orders')
                                )
                            or (ordername='MA_000'
                                and order_code like 'Waiting for redeploy'
                                )
                            )
                 Order By ordername
                 Limit 1
                 ) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Invalid power to process</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check some movement
IF (sr_major < 1 and sr_minor < 1) or sr_minor < 0 or sr_major < 0 THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>No troops</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("Major",sr_major)
                                         ,sf_fxml("Minor",sr_minor)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
IF Upper(sr_terrname_from) = Upper(sr_terrname_to) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>No distance</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("TerrnameFrom",sr_terrname_from)
                                         ,sf_fxml("TerrnameTo",sr_terrname_to)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;

-- Check from territory and ownership
If sr_terrname_from not in (Select terrname
                            From sp_places p, sp_board b
                            Where p.terrno=b.terrno
                             and b.gameno=sr_gameno
                             and b.userno=sr_userno
                             and Length(terrtype)=4) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid From Territory</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;

-- Get info about from territory
Select terrno Into sr_terrno_from From sp_places Where terrname=sr_terrname_from;
Select major, minor
Into   sr_major_from_before, sr_minor_from_before
From   sp_board
Where  gameno=sr_gameno
 and terrno=sr_terrno_from
;

-- Check forces are available
If sr_major > sr_major_from_before or sr_minor > sr_minor_from_before Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Not enough forces available to move</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                         ,sf_fxml("TerritoryFromMajor",sr_major_from_before)
                                         ,sf_fxml("TerritoryFromMinor",sr_minor_from_before)
                                         ,sf_fxml("Major",sr_major)
                                         ,sf_fxml("Minor",sr_minor)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;

IF sr_terrname_to not in (Select terrname
                          From sp_places p, sp_board b
                          Where p.terrno=b.terrno
                           and b.gameno=sr_gameno
                           and b.userno=sr_userno
                           and Length(terrtype)=4
                          -- Add in Neutroned territories
                          Union
                          Select terrname
                          From sp_places p, sp_board b
                          Where p.terrno=b.terrno
                           and b.gameno=sr_gameno
                           and b.userno=-10
                           and b.passuser=sr_userno
                           and Length(terrtype)=4
                          -- Add in redeployment territories
                          Union
                          Select terrname
                          From   sp_board b, sp_places p, sp_orders o
                          Where b.gameno=sr_gameno
                           and o.gameno=sr_gameno
                           and b.terrno=p.terrno
                           and Length(terrtype)=4
                           and b.userno!=sr_userno
                           and b.major=0 and b.minor=0
                           and o.ordername='REDEPLOY'
                           and Concat(' ',ExtractValue(order_code,'/Terrno'),' ') like Concat('% ',b.terrno,' %')
                          ) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid To territory</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("TerritoryFrom",sr_terrname_from)
                                         ,sf_fxml("TerritoryTo",sr_terrname_to)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select b.terrno, userno, major, minor
Into sr_terrno_to, sr_userno_to_before, sr_major_to_before, sr_minor_to_before
From sp_places p, sp_board b
Where b.gameno=sr_gameno and p.terrno=b.terrno and terrname=sr_terrname_to
;

-- Check available resources
Select Ceil(fly_jm*sr_major+fly_nm*sr_minor)
       ,Ceil(fly_jo*sr_major+fly_no*sr_minor)
       ,Ceil(fly_jg*sr_major+fly_ng*sr_minor)
Into mcost, ocost, gcost
From sp_tech
Where tech_level=sr_tech
;
IF mcost > sr_minerals or ocost > sr_oil or gcost > sr_grain THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Not enough resource available to move</Reason>"
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
    Leave sproc;
End If;

-- Update resources
Update sp_resource
Set minerals=minerals-mcost
 ,oil=oil-ocost
 ,grain=grain-gcost
Where gameno=sr_gameno
 and powername=sr_powername
;

-- Update territory from
call sr_take_territory(sr_gameno, sr_terrname_from, sr_powername, sr_major_from_before-sr_major, sr_minor_from_before-sr_minor);

-- Update territory to
IF sr_userno_to_before = -10 THEN
    -- Change powername from Neutron
    Call sr_take_territory(sr_gameno, sr_terrname_to, sr_powername, sr_major+sr_major_to_before, sr_minor+sr_minor_to_before);
ELSEIF sr_userno != sr_userno_to_before THEN
    -- Change powername on redeploy
    Call sr_take_territory(sr_gameno, sr_terrname_to, sr_powername, sr_major, sr_minor);
ELSE
    Update sp_board
    Set major=major+sr_major
     ,minor=minor+sr_minor
    Where gameno=sr_gameno
     and terrno=sr_terrno_to
    ;
END IF;
Select major, minor Into sr_major_to_after, sr_minor_to_after From sp_board Where gameno=sr_gameno and terrno=sr_terrno_to;

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
 Values (sr_gameno, sr_userno, Concat("You have moved "
                                     ,sf_format_troops("LAND", sr_major, sr_minor)
                                     ," from ",sr_terrname_from
                                     ," to ",sr_terrname_to
                                     ," costing "
                                     ,Case When mcost=0 Then '' When mcost=1 Then '1 mineral' Else Concat(mcost,' minerals,') End
                                     ,Case When ocost=0 Then '' Else Concat(ocost,' oil') End
                                     ,Case When ocost > 0 and gcost > 0 Then ' and ' Else '' End
                                     ,Case When gcost=0 Then '' Else Concat(gcost,' grain') End
                                     ,". There are now ",sf_format_troops("LAND",sr_major_from_before-sr_major,sr_minor_from_before-sr_minor)
                                     ," in ",sr_terrname_from
                                     ," and ",sf_format_troops("LAND",sr_major_to_after,sr_minor_to_after)
                                     ," in ",sr_terrname_to
                                     ,"."
                                     )
        );
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, 0, Concat(sr_powername, " has moved troops from ",sr_terrname_from," to ",sr_terrname_to,"."));

-- Always move queue
Update sp_orders Set order_code='Orders processed' Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_userno and order_code like 'Waiting%';
call sr_move_queue(sr_gameno);

END sproc;
END
$$

Delimiter ;
/*
Call sr_take_territory(48,'Iran','Europe',1,5);
Call sr_take_territory(48,'India','Europe',0,0);
Call sr_take_territory(48,'Burma','Europe',0,0);
Update sp_resource Set minerals=0, oil=0, grain=0 Where gameno=48 and powername='Europe';
delete from sp_old_orders;
delete from sp_message_queue;

-- Check gameno
Call sr_4_move_fly (-1, 'Europe', 'Iran', 'India', 0, 5);

-- Check powername
Call sr_4_move_fly (48, 'Dewsbury', 'Iran', 'India', 0, 5);

-- Check from territory
Call sr_4_move_fly (48, 'Europe', 'Iranx', 'India', 0, 5);
Call sr_4_move_fly (48, 'China', 'Iran', 'India', 0, 5);
Call sr_4_move_fly (48, 'Europe', 'Bay of Bengal','India', 0, 5);

-- Check troops available
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 0, 0);
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 10, 15);
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 10, 5);
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 0, 15);

-- Check to territory
Call sr_4_move_fly (48, 'Europe', 'Iran', 'Halifax', 0, 5);
Call sr_4_move_fly (48, 'Europe', 'Iran', 'Iberia', 0, 5);
Update sp_board set passuser=3227 Where gameno=48 and terrno=42;
Call sr_4_move_fly (48, 'Europe', 'Iran', 'Iraq', 0, 5);

-- Check available resources
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 0, 5);
Update sp_resource Set max_minerals=12, minerals=10, oil=10, grain=10 Where gameno=48 and powername='Europe';

-- Actual move
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 0, 2);
Call sr_4_move_fly (48, 'Europe', 'Iran', 'India', 1, 2);
Call sr_4_move_fly (48, 'Europe', 'India', 'Burma', 1, 0);

select * from sp_message_queue;
select * from sv_map Where gameno=48 and terrname in ('Iran','India','Burma');
select * from sp_old_orders;
select * from sp_resource where gameno=48 and powername='Europe';
*/