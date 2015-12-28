use asupcouk_asup;
Drop procedure if exists sr_4_lstar_battle;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_4_lstar_battle` (sr_gameno INT, sr_attacking_powername VARCHAR(15), sr_defending_powername VARCHAR(15))
BEGIN
sproc:BEGIN

-- $Id: sr_4_lstar_battle.sql 323 2015-12-19 21:25:27Z paul $
-- Declare variables
DECLARE proc_name TEXT Default "SR_4_LSTAR_BATTLE";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE att_userno INT Default 0;
DECLARE att_lstars INT Default 0;
DECLARE att_ksats INT Default 0;
DECLARE att_lstars_after INT Default 0;
DECLARE att_ksats_after INT Default 0;
DECLARE att_dead TEXT Default "Y";
DECLARE att_hits INT Default 0;
DECLARE def_userno INT Default 0;
DECLARE def_lstars INT Default 0;
DECLARE def_ksats INT Default 0;
DECLARE def_lstars_after INT Default 0;
DECLARE def_ksats_after INT Default 0;
DECLARE def_dead TEXT Default "Y";
DECLARE def_hits INT Default 0;
DECLARE i INT;
DECLARE message_text TEXT;
DECLARE def_powername_orders TEXT;
DECLARE battle_round INT;
DECLARE battle_status TEXT;

-- Check game and phase
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=4)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;


-- Get current L-Stars, K-Sats and status
Select userno, lstars, ksats, dead
Into att_userno, att_lstars, att_ksats, att_dead
From sp_resource
Where gameno=sr_gameno
 and powername=sr_attacking_powername
;

Select userno, lstars, ksats, dead
Into def_userno, def_lstars, def_ksats, def_dead
From sp_resource
Where gameno=sr_gameno
 and powername=sr_defending_powername
;

-- Check attacking power name
IF att_dead != 'N' THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid attacking powername</Reason><PowerName>",sr_attacking_powername,"</PowerName></FAIL>"));
    LEAVE sproc;
END IF;

-- Check right time for orders
IF att_userno != (Select waiting_userno From sv_next_powers Where gameno=sr_gameno) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid user, not their turn</Reason><PowerName>",sr_attacking_powername,"</PowerName><Userno>",att_userno,"</Userno></FAIL>"));
    LEAVE sproc;
END IF;

-- Check some lstars or ksats are there
IF att_lstars = 0 and att_ksats = 0 THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Nothing to attack with</Reason>"
                                         ,"<PowerName>",sr_attacking_powername,"</PowerName>"
                                         ,"<L-Stars>",att_lstars,"</L-Stars>"
                                         ,"<K-Sats>",att_ksats,"</K-Sats>"
                                         ,"<Userno>",att_userno,"</Userno>"
                                         ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check defending powername
IF sr_defending_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N') THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid defending powername</Reason><PowerName>",sr_defending_powername,"</PowerName></FAIL>"));
    LEAVE sproc;
END IF;
IF def_userno not in (Select userno From sp_resource Where gameno=sr_gameno and (lstars>0 or ksats>0)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid defender, nothing to attack</Reason><PowerName>",sr_defending_powername,"</PowerName><Userno>",def_userno,"</Userno></FAIL>"));
    LEAVE sproc;
END IF;
-- Check someone else is not under attack
Select order_code Into def_powername_orders From sp_orders Where gameno=sr_gameno and userno=att_userno and ordername='def_power';
IF def_powername_orders is not null and sr_defending_powername != def_powername_orders THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid defender, someone else under attack</Reason><PowerName>",sr_defending_powername,"</PowerName><Userno>",def_userno,"</Userno></FAIL>"));
    LEAVE sproc;
END IF;

-- Start processing the attack
Call sr_4_attack_set(sr_gameno, "Satellite", sr_defending_powername, null, null);

-- Set message start
Set message_text=Concat("<LSTAR>"
                       ,sf_fxml("AttPowername",sr_attacking_powername)
                       ,sf_fxml("DefPowername",sr_defending_powername)
                       );
-- Get round number
Select message, messageno, ExtractValue(message_text,'/LSTAR/Rounds')+1
Into message_text, i, battle_round
From sp_message_queue
Where message like Concat(message_text,'%');

-- Resolve attacking L-Stars
Set i=0;
WHILE i < att_lstars DO
    Set att_hits = att_hits + Floor(Ceil(Rand()*6)/6);
    Set i = i +1;
END WHILE;
-- Resolve attacking K-Sats
Set i=0;
WHILE i < att_ksats DO
    Set att_hits = att_hits + Floor(Ceil(Rand()*6)/4);
    Set i = i +1;
END WHILE;
-- Resolve defending L-Stars
Set i=0;
WHILE i < def_lstars DO
    Set def_hits = def_hits + Floor(Ceil(Rand()*6)/6);
    Set i = i +1;
END WHILE;
-- Resolve defending K-Sats
Set i=0;
WHILE i < def_ksats DO
    Set def_hits = def_hits + Floor(Ceil(Rand()*6)/4);
    Set i = i +1;
END WHILE;

-- Remove attacking forces, L-Stars first
Set att_lstars_after = Greatest(0, att_lstars-def_hits);
Set att_ksats_after = Least(att_ksats, Greatest(0, att_ksats+att_lstars-def_hits));

-- Remove defending forces, L-Stars first
Set def_lstars_after = Greatest(0, def_lstars-att_hits);
Set def_ksats_after = Least(def_ksats, Greatest(0, def_ksats+def_lstars-att_hits));

-- Update resource table
Update sp_resource Set lstars=att_lstars_after, ksats=att_ksats_after Where gameno=sr_gameno and powername=sr_attacking_powername;
Update sp_resource Set lstars=def_lstars_after, ksats=def_ksats_after Where gameno=sr_gameno and powername=sr_defending_powername;

-- Set old orders success
Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
Values (sr_gameno, sr_turnno, sr_phaseno, proc_name, Concat("<SUCCESS>"
                                     ,"<AttackingPowerName>",sr_attacking_powername,"</AttackingPowerName>"
                                     ,"<L-Stars>",att_lstars,"</L-Stars>"
                                     ,"<K-Sats>",att_ksats,"</K-Sats>"
                                     ,"<DefenderHits>",def_hits,"</DefenderHits>"
                                     ,"<L-StarsAfter>",att_lstars_after,"</L-StarsAfter>"
                                     ,"<K-SatsAfter>",att_ksats_after,"</K-SatsAfter>"
                                     ,"<DefendingPowerName>",sr_defending_powername,"</DefendingPowerName>"
                                     ,"<L-Stars>",def_lstars,"</L-Stars>"
                                     ,"<K-Sats>",def_ksats,"</K-Sats>"
                                     ,"<AttackerHits>",att_hits,"</AttackerHits>"
                                     ,"<L-StarsAfter>",def_lstars_after,"</L-StarsAfter>"
                                     ,"<K-SatsAfter>",def_ksats_after,"</K-SatsAfter>"
                                     ,"</SUCCESS>"));

-- See if fighting can continue
IF def_lstars_after+def_ksats_after > 0 and att_lstars_after+att_ksats_after>0 THEN
    Set battle_status='Continue';
ELSE
    Set battle_status='Over';
END IF;

-- Insert new message
IF (battle_round is null) THEN
    Set message_text = Concat(message_text
                              ,"<RESULT>"
                              ,sf_format_xml('ala','Attacking L-Stars remaining',att_lstars_after)
                              ,sf_format_xml('aka','Attacking K-Sats remaining',att_ksats_after)
                              ,sf_format_xml('dla','Defending L-Stars remaining',def_lstars_after)
                              ,sf_format_xml('dka','Defending K-Sats remaining',def_ksats_after)
                              ,sf_format_xml('status','Battle Status',battle_status)
                              ,"</RESULT>"
                              ,sf_fxml('Rounds','1')
                              ,"<R Id='R1'>"                              ,sf_format_xml('att_lstars','Attacking L-Stars',att_lstars)
                              ,sf_format_xml('att_ksats','Attacking K-Sats',att_ksats)
                              ,sf_format_xml('att_hits','Attacking Hits',att_hits)
                              ,sf_format_xml('def_lstars','Defending L-Stars',def_lstars)
                              ,sf_format_xml('def_ksats','Defending K-Sats',def_ksats)
                              ,sf_format_xml('def_hits','Defending Hits',def_hits)
                              ,"</R>"
                              ,"</LSTAR>"
                              );
    Insert Into sp_message_queue (gameno, userno, message)
     Values (sr_gameno, -7, message_text);
    Insert Into sp_message_queue (gameno, userno, to_email, message)
     Values (sr_gameno, def_userno, -1, Concat("Your Satellites have been attacked by Satellites owned by ",sr_attacking_powername,"."));
ELSE
    -- Update XML message
    Select message, messageno Into message_text, i From sp_message_queue Where message like Concat(message_text,'%');
    Set message_text = UpdateXML(message_text,'/LSTAR/RESULT/ala',sf_format_xml('ala','Attacking L-Stars remaining',att_lstars_after));
    Set message_text = UpdateXML(message_text,'/LSTAR/RESULT/aka',sf_format_xml('aka','Attacking K-Sats remaining',att_ksats_after));
    Set message_text = UpdateXML(message_text,'/LSTAR/RESULT/dla',sf_format_xml('dla','Defending L-Stars remaining',def_lstars_after));
    Set message_text = UpdateXML(message_text,'/LSTAR/RESULT/dka',sf_format_xml('dka','Defending K-Sats remaining',def_ksats_after));
    Set message_text = UpdateXML(message_text,'/LSTAR/RESULT/status',sf_format_xml('status','Battle Status',battle_status));
    Set message_text = UpdateXML(message_text,'/LSTAR/Rounds'
                                ,Concat(sf_fxml('Rounds',battle_round)
                                       ,"<R Id='R",ExtractValue(message_text,'/LSTAR/Rounds')+1,"'>"
                                       ,sf_format_xml('att_lstars','Attacking L-Stars',att_lstars)
                                       ,sf_format_xml('att_ksats','Attacking K-Sats',att_ksats)
                                       ,sf_format_xml('att_hits','Attacking Hits',att_hits)
                                       ,sf_format_xml('def_lstars','Defending L-Stars',def_lstars)
                                       ,sf_format_xml('def_ksats','Defending K-Sats',def_ksats)
                                       ,sf_format_xml('def_hits','Defending Hits',def_hits)
                                       ,"</R>"
                                       )
                                );
    Update sp_message_queue Set message=message_text Where messageno=i;
END IF;

IF (battle_status='Over') THEN
    -- Move queue along
    Update sp_orders Set order_code='Orders processed'
    Where gameno=sr_gameno
     and userno=att_userno
     and turnno=sr_turnno
     and phaseno=sr_phaseno
     and (order_code like 'Waiting%' or order_code='Orders processing')
    ;
    Call sr_move_queue(sr_gameno);
END IF;

-- Return message text
Select message_text;

-- Check L-Star slots after
Call sr_check_lstar_slots(sr_gameno);

END sproc;
END
$$

Delimiter ;

/*
delete from sp_old_orders;
delete from sp_message_queue;
delete from sp_messages;

Update sp_game set turnno=4, phaseno=4 where gameno=48;

Update sp_resource Set mia=0 Where gameno=48;
Update sp_resource Set mia=9 Where powername not in ('Europe','China','Africa') and gameno=48;

Delete from sp_orders Where gameno=48;
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,4,5,'ORDSTAT','First');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,4,4,'ORDSTAT','In queue - 9');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,4,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,4,4,'ORDSTAT','Waiting for orders');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,4,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,4,5,'ORDSTAT','First');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,4,5,'ORDSTAT','First');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,4,4,'ORDSTAT','In queue - 1');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,4,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,4,5,'ORDSTAT','First');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,4,4,'MA_001_ATT','Extra Move/Attack 1');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,4,5,'ORDSTAT','Passed');
INSERT INTO sp_orders (gameno, userno, turnno, phaseno, ordername, order_code) select gameno, userno, 4,6,'ORDSTAT','Passed' from sp_resource where gameno=48 and dead='N';
INSERT INTO sp_orders (gameno, userno, turnno, phaseno, ordername, order_code) select gameno, userno, 4,7,'ORDSTAT','Passed' from sp_resource where gameno=48 and dead='N';


update sp_resource set lstars=0, ksats=0 where gameno=48 and powername='Europe';
update sp_resource set lstars=2, ksats=0 where gameno=48 and powername='Africa';
update sp_resource set lstars=0, ksats=0 where gameno=48 and powername='Canada';
update sp_resource set lstars=99, ksats=99 where gameno=48 and powername='China';

-- Check gameno
-- call sr_4_lstar_battle(21,'Europe','Africa');

-- Check attacking power, assume it is Europe in game 48 to attack
-- call sr_4_lstar_battle(48,'Pink','Africa');
-- call sr_4_lstar_battle(48,'China','Africa');
-- call sr_4_lstar_battle(48,'Europe','Africa');
update sp_resource set lstars=5, ksats=1 where gameno=48 and powername='Europe';
update sp_resource set lstars=2, ksats=2 where gameno=48 and powername!='Europe';

-- Check defending power
-- call sr_4_lstar_battle(48,'Europe','Pink');
-- call sr_4_lstar_battle(48,'Europe','Canada');

-- Actual battle round
set @sr_debug='Y';
call sr_4_lstar_battle(48,'Europe','Africa');
select * from sv_current_orders where gameno=48 and powername in ('Europe','Africa');
-- Fail attacking someone else
-- call sr_4_lstar_battle(48,'Europe','China');

-- Second battle round, ends battle
Update sp_resource Set lstars=1, ksats=0 Where gameno=48 and powername='Africa';
call sr_4_lstar_battle(48,'Europe','Africa');
select * from sv_current_orders where gameno=48 and powername in ('Europe','Africa');

-- Attack someone else legitimately
select powername, userno, lstars from sp_resource where gameno=48;
select gameno, userno, count(*) from sp_lstars group by 1, 2;
call sr_4_lstar_battle(48,'Europe','China');
select * from sv_current_orders where gameno=48 and powername in ('Europe','Africa','China');
select powername, userno, strategic_tech, lstars, ksats from sp_resource where gameno=48;
select gameno, userno, count(*) from sp_lstars group by 1, 2;


/*
select * from sp_old_orders;
select * from sp_message_queue;
select r.gameno, powername, strategic_tech, lstars, count(distinct lstarno), sum(lstarno is not null)
from sp_resource r
left join sp_lstars l on r.gameno=l.gameno and r.userno=l.userno
where r.gameno=48
group by 1, 2
;

call sr_4_lstar_battle(48,'Europe','Canada');


-- insert into sp_messages (gameno, userno, message) select gameno, userno, message from sp_message_queue;
-- delete from sp_message_queue;

-- select ExtractValue(message,'/LSTAR/RESULT/status') from sp_message_queue Where gameno=48 and userno=-7;
-- select ExtractValue(message,'/LSTAR/DefPowername') from sp_message_queue Where gameno=48 and userno=-7;
-- select * from sp_orders where userno=3227;
/*
update sp_resource set lstars=99, ksats=50 where gameno=48 and powername='Europe';
update sp_resource set lstars=50, ksats=10 where gameno=48 and powername!='Europe';
*/
