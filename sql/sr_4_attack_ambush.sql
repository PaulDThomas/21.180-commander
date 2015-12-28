Use `asupcouk_asup`;
Drop procedure if exists `asupcouk_asup`.`sr_4_attack_ambush`;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_4_attack_ambush` (sr_gameno INT
				                                      ,sr_powername VARCHAR(15)
				                                      ,sr_boomerno INT
				                                      ,sr_att_major CHAR(1)
				                                      )
BEGIN
sproc:BEGIN

-- $Id: sr_4_attack_ambush.sql 247 2014-07-16 20:40:38Z paul $
DECLARE proc_name TEXT Default "SR_4_ATTACK_AMBUSH";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_def_userno INT Default 0;
DECLARE sr_def_powername VARCHAR(15);
DECLARE sr_terrname VARCHAR(25);
DECLARE sr_terrno INT Default 0;
DECLARE sr_major_before INT Default 0;
DECLARE sr_minor_before INT Default 0;
DECLARE sr_major_after INT Default 0;
DECLARE sr_minor_after INT Default 0;
DECLARE sr_attack_array TEXT;
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
IF sr_powername not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Power</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select userno Into sr_userno From sp_resource Where gameno=sr_gameno and powername=sr_powername;

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

-- Check boomer 
IF sr_boomerno not in (Select boomerno From sp_boomers Where gameno=sr_gameno and userno=sr_userno and visible!='Y') THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid boomer</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Boomer",sr_boomerno)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select m.terrno, m.terrname, m.userno, m.powername, m.major, m.minor
Into sr_terrno, sr_terrname, sr_def_userno, sr_def_powername, sr_major_before, sr_minor_before
From sp_boomers b
Left Join sv_map m On b.gameno=m.gameno and b.terrno=m.terrno
Where b.gameno=sr_gameno and b.userno=sr_userno and b.boomerno=sr_boomerno
;

IF @sr_debug!='N' THEN 
	Select "Ambushing", sr_terrno, sr_terrname, sr_def_userno, sr_def_powername, sr_major_before, sr_minor_before;
END IF;

-- Check territory and ownership
IF sr_def_userno=sr_userno THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Stop hitting yourself</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Territory",sr_terrname)
                   ,sf_fxml("TerrNo",sr_terrno)
                   ,sf_fxml("Defender",sr_def_powername)
                   ,sf_fxml("DefUserNo",sr_def_userno)
                   ,sf_fxml("Boomer",sr_boomerno)
                   ,sf_fxml("MajorBefore",sr_major_before)
                   ,sf_fxml("MinorBefore",sr_minor_before)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Check retaliation
IF sr_retaliation=1 and sr_ret_userno!=sr_def_userno THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Bad retaliation</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("DefUserNo",sr_def_userno)
                   ,sf_fxml("RetaliationUserNo",sr_ret_userno)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Do not attack major unless specified
IF sr_att_major != 'Y' THEN
    Set sr_att_major = 'N';
END IF;

-- Rise to the surface...
Update sp_boomers Set visible='Y' Where gameno=sr_gameno and userno=sr_userno and boomerno=sr_boomerno;

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat("You have ambushed ",sr_def_powername
		       ," in ",sr_terrname
               ," using your boomer hidden there."
               )
        );
-- Attacked message
IF sr_def_userno > 0 THEN
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_def_userno, -1
            ,Concat("You have been ambushed by ",sr_powername
                   ," in ",sr_terrname
                   ," using a boomer."
                   )
            );
END IF;
-- General message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, 0
        ,Concat(sr_powername
               ," has ambushed ",sr_def_powername
               ," with a boomer in ",sr_terrname
               ,"."));

-- Add redeploys and retaliations
Call sr_4_attack_set(sr_gameno, "Ambush", sr_def_powername, sr_terrname, sr_terrname);

-- FIGHT!  First attack will be free for the boomer...
Set sr_attack_array = Concat(sf_fxml('MaxRounds',2),sf_fxml('AttackBoomers',1),sf_fxml('AttackNavies',0),sf_fxml('AttackMajor',sr_att_major));
Call sr_attack(sr_gameno, sr_terrname, sr_powername, sr_attack_array);

-- Remove defenders resources if necessary
IF ExtractValue(sr_attack_array, '//DefAction') = 'Defend' THEN
    Update sp_resource
    Set minerals=minerals-1, oil=oil-1, grain=grain-1
    Where gameno=sr_gameno
     and powername=sr_def_powername
    ;
END IF;

-- Get number of boats returned
Select ExtractValue(sr_attack_array,'//TerritoryBoomers')
       ,ExtractValue(sr_attack_array, '//TerritoryNavies')
       ,ExtractValue(sr_attack_array, '//AttackResult')
Into sr_major_after
     ,sr_minor_after
     ,sr_result
;

-- Remove boomer if the attack was a failure
IF sr_result = 'Defeat' THEN
	Delete From sp_boomers Where gameno=sr_gameno and userno=sr_userno and boomerno=sr_boomerno;
END IF;

-- Set old orders success
Insert into sp_old_orders (gameno, ordername, order_code, userno, turnno, phaseno)
 Values (sr_gameno, proc_name, Concat("<SUCCESS>"
                                     ,sf_fxml("Gameno",sr_gameno)
                                     ,sf_fxml("Powername",sr_powername)
                                     ,sf_fxml("BoomerNo",sr_boomerno)
                                     ,sf_fxml("Territory",sr_terrname)
                                     ,sf_fxml("MajorBefore",sr_major_before)
                                     ,sf_fxml("MinorBefore",sr_minor_before)
                                     ,sf_fxml("MajorAfter",sr_major_after)
                                     ,sf_fxml("MinorAfter",sr_minor_after)
									 ,sf_fxml("Result",sr_result)
                                     ,"</SUCCESS>")
        ,sr_userno, sr_turnno, sr_phaseno);

-- User message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno
        ,Concat(Case When sr_result='Victory' Then "Your forces were victorious against " Else "You were defeated by " End, sr_def_powername,". "
               ,sr_terrname," is now guarded by "
               ,sf_format_troops("SEA",sr_major_after,sr_minor_after)
               ,". "
               )
        );

-- Attacked message
IF sr_def_userno > 0 THEN
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, sr_def_userno, -1
            ,Concat(Case When sr_result='Defeat' and sr_major_after=0 and sr_minor_after=0 Then "Your forces were wiped out defending the territory. "
                         When sr_result='Defeat' Then "Your forces were victorious. "
                         Else "You were defeated. "
                         End
                   ,sr_terrname," is now guarded by "
                   ,sf_format_troops("SEA",sr_major_after,sr_minor_after)
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
