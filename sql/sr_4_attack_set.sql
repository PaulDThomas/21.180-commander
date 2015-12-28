use asupcouk_asup;
Drop procedure if exists sr_4_attack_set;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_4_attack_set` (sr_gameno INT, sr_action TEXT, sr_def_powername varchar(15), sr_def_terrname varchar(25), sr_att_terrname varchar(25))
BEGIN
sproc:BEGIN

-- Add redeploys and retaliations to orders table
-- $Id: sr_4_attack_set.sql 244 2014-07-13 16:44:49Z paul $
DECLARE proc_name TEXT DEFAULT "SR_4_ATTACK_SET";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_att_powername  varchar(15);
DECLARE sr_att_userno INT DEFAULT 0;
DECLARE sr_att_terrno INT DEFAULT 0;
DECLARE sr_def_userno INT DEFAULT 0;
DECLARE sr_def_terrno INT DEFAULT 0;
DECLARE sr_retaliation INT DEFAULT 0;
DECLARE sr_home_user INT DEFAULT 0;

-- Check game is valid, in move/attack phase
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=4)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Get next in queue
Select o.userno, powername, (ordername='MA_000')
Into sr_att_userno, sr_att_powername, sr_retaliation
From   sp_orders o
Left Join sp_resource r On o.gameno=r.gameno and o.userno=r.userno
Where  o.gameno=sr_gameno
 and o.phaseno=4
 and (order_code like 'Waiting%' or order_code='Orders processed' or order_code='Orders processing')
Order By ordername
Limit 1;

IF @sr_debug='X' THEN
    Select sr_att_powername, powername From sp_resource Where gameno=sr_gameno and powername!=sr_att_powername and dead='N';
END IF;

-- Check defending powername
IF sr_def_powername in ('locals','Warlords','Pirates','nuclear waste','neutron bombardment','neutral','nuked') or sr_def_powername like 'neutron - %' THEN Set sr_def_powername=null; END IF;
IF sr_def_powername is not null
   and sr_def_powername not in (Select powername From sp_resource Where gameno=sr_gameno and powername!=sr_att_powername and dead='N') THEN
	Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code)
	Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, proc_name,
            sf_fxml('FAIL', Concat(sf_fxml('Reason','Bad defending powername')
                                  ,sf_fxml('DefendingPowername',sr_def_powername)
								  )
					)
			)
	;
	LEAVE sproc;
ELSE
    Select userno Into sr_def_userno From sp_resource Where gameno=sr_gameno and powername=sr_def_powername;
END IF;

-- Check defending territory, could have already been taken
Select terrno Into sr_def_terrno From sp_places Where terrname=sr_def_terrname;
IF sr_def_terrname is not null
   and sr_def_terrno not in (Select terrno From sp_board Where gameno=sr_gameno and Case When sr_def_powername is not null Then userno in (sr_att_userno,sr_def_userno,0) Else (userno<=0 or userno=sr_att_userno) End) THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code)
		Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, proc_name,
	            sf_fxml('FAIL', Concat(sf_fxml('Reason','Bad defending territory')
	                                  ,sf_fxml('DefendingPowername',sr_def_powername)
	                                  ,sf_fxml('DefendingTerrName',sr_def_terrname)
	                                  ,sf_fxml('DefendingTerrNo',sr_def_terrno)
									  )
						)
				)
		;
    LEAVE sproc;
END IF;

-- At least one of def_terrno or def_userno must be set
IF sr_def_terrno=0 and sr_def_userno=0 THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code)
		Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, proc_name,
	            sf_fxml('FAIL', Concat(sf_fxml('Reason','No defending territory or power')
	                                  ,sf_fxml('DefendingPowername',sr_def_powername)
	                                  ,sf_fxml('DefendingTerritory',sr_def_terrname)
									  )
						)
				)
		;
    LEAVE sproc;
END IF;


-- Check attacking territory, may have gone neutral or back to previous superpower 
Select b.terrno, Coalesce(r.userno, 0)
Into sr_att_terrno, sr_home_user 
From sp_board b
Left Join sp_places p On b.terrno=p.terrno
Left Join sp_powers pw On p.terrtype=pw.terrtype
Left Join sp_resource r On pw.powername=r.powername and b.gameno=r.gameno and r.dead='N'
Where terrname=sr_att_terrname
 and b.gameno=sr_gameno
;
IF sr_att_terrname is not null
   and sr_action != 'Ambush'
   and sr_att_terrno not in (Select terrno From sp_board Where gameno=sr_gameno and userno in (sr_att_userno,sr_home_user)) THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, userno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, proc_name,
            sf_fxml('FAIL', Concat(sf_fxml('Reason','Bad attacking territory')
                                  ,sf_fxml('AttackingPowername',sr_att_powername)
                                  ,sf_fxml('AttackingTerritory',sr_att_terrname)
                                  )
                    )
            )
    ;
    LEAVE sproc;
END IF;

IF @sr_debug='X' THEN
    Select 'Attack setting';
END IF;


-- Set orders processing if not retaliation and currently waiting
Update sp_orders Set order_code='Orders processing'
Where gameno=sr_gameno
 and userno=sr_att_userno
 and phaseno=4
 and ordername='ORDSTAT'
 and order_code='Waiting for orders'
 and sr_retaliation=0
;

-- Add in action order
IF not exists(Select * From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_att_userno and ordername='Action') THEN
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, "Action", sr_action);
END IF;

-- Add in def_power order
IF not exists(Select * From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_att_userno and ordername='def_power') and sr_def_powername is not null THEN
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, "def_power", sr_def_powername);
END IF;

-- Add in def_terr order
IF sr_def_terrname is not null and not exists(Select * From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_att_userno and ordername='def_terr') THEN
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, "def_terr", sr_def_terrname);
END IF;

-- Add in att_terr order
IF sr_att_terrname is not null and not exists(Select * From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_att_userno and ordername='att_terr') THEN
    Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, sr_att_userno, "att_terr", sr_att_terrname);
END IF;


-- Add redeploys and retaliations is a Superpower has been attacked
IF sr_def_userno > 0 THEN
    -- Add redeploy for attacker
    IF 0 = (Select Count(*) From sp_orders Where gameno=sr_gameno and userno=sr_att_userno and ordername like 'MA_%_REAT') THEN
        Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername)
         Select sr_gameno, sr_att_userno, sr_turnno, 4, Concat('MA_',LPad(Coalesce(Max(Substr(ordername,4,3))+1,1),3,'0'),'_REAT')
         From   sp_orders
         Where  gameno=sr_gameno and turnno=sr_turnno and phaseno=4 and ordername like 'MA_%'
         ;
    END IF;
    -- Attack to redeploy terr
    IF sr_def_terrno > 0 and Exists(Select * From sp_orders Where gameno=sr_gameno and userno=sr_att_userno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='REDEPLOY') THEN
        Update sp_orders Set order_code=Concat(order_code,sf_fxml('Terrno',sr_def_terrno)) Where gameno=sr_gameno and userno=sr_att_userno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='Redeploy';
    ELSEIF sr_def_terrno > 0 THEN
        Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code) Values (sr_gameno, sr_att_userno, sr_turnno, sr_phaseno, 'REDEPLOY', sf_fxml('Terrno',sr_def_terrno));
    END IF;

    -- Add redeploy for defender
    IF 0 = (Select Count(*) From sp_orders Where gameno=sr_gameno and userno=sr_def_userno and ordername like 'MA_%_REDE') THEN
        Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername)
         Select sr_gameno, sr_def_userno, sr_turnno, 4, Concat('MA_',LPad(Coalesce(Max(Substr(ordername,4,3))+1,1),3,'0'),'_REDE')
         From   sp_orders
         Where  gameno=sr_gameno and turnno=sr_turnno and phaseno=4 and ordername like 'MA_%'
         ;
    END IF;
    -- Defender redeploy terr
    IF sr_def_terrno > 0 and Exists(Select * From sp_orders Where gameno=sr_gameno and userno=sr_def_userno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='REDEPLOY') THEN
        Update sp_orders Set order_code=Concat(order_code,sf_fxml('Terrno',sr_def_terrno)) Where gameno=sr_gameno and userno=sr_def_userno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='Redeploy';
    ELSEIF sr_def_terrno > 0 THEN
        Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code) Values (sr_gameno, sr_def_userno, sr_turnno, sr_phaseno, 'REDEPLOY', sf_fxml('Terrno',sr_def_terrno));
    END IF;

    -- Add retaliation
    IF 0 = (Select Count(*) From sp_orders Where gameno=sr_gameno and userno=sr_def_userno and ordername like 'MA_%_RET' and order_code=sr_att_userno)
       and sr_retaliation = 0 THEN
        Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
         Select sr_gameno, sr_def_userno, sr_turnno, 4, Concat('MA_',LPad(Coalesce(Max(Substr(ordername,4,3))+1,1),3,'0'),'_RET'), sr_att_userno
         From   sp_orders
         Where  gameno=sr_gameno and turnno=sr_turnno and phaseno=4 and ordername like 'MA_%'
         ;
    END IF;
END IF;

IF @sr_debug='X' THEN
    Select 'Attack set';
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;
/*
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
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,4,4,'MA_002_ATT','Extra Move/Attack 2');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,4,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,4,5,'ORDSTAT','Passed');

Call sr_take_territory(48,'Iran','Europe',1,4);
Call sr_take_territory(48,'Iberia','Europe',1,4);
Call sr_take_territory(48,'Persian Gulf','Europe',0,1);
Call sr_take_territory(48,'Iraq','Africa',0,5);
Call sr_take_territory(48,'Arabian Sea','Africa',0,3);
Call sr_take_territory(48,'Bay of Biscay','Africa',0,1);
Call sr_take_territory(48,'Turkey','China',0,3);
Call sr_take_territory(48,'Mediterranean Sea','Neutral',0,3);
Call sr_take_territory(48,'Eastern Europe','Europe',0,6);
Delete From sp_messages;
Delete From sp_old_orders;

-- Check gameno
Set @sr_debug='N';
-- Call sr_4_attack_set(99,'Satellite','China','','');

-- Check def power
-- Call sr_4_attack_set(48,'Satellite','Arabia','','');
-- Call sr_4_attack_set(48,'Satellite','Europe','','');

-- Check def terr
-- Call sr_4_attack_set(48,'Ground','Africa','Turkey','Iran');
-- Call sr_4_attack_set(48,'Ground','Africa','Iraq','Turkey');

-- Check def power and terr
-- Call sr_4_attack_set(48, 'Sea', null, null, 'Iberia');

-- Sat Off OK
Set @sr_debug='N';
Call sr_4_attack_set(48,'Satellite','China',null,null);
update sp_orders set order_code='Orders processed' Where order_code='Orders processing';
Select * From sv_current_orders where gameno=48 and powername in ('Africa','Europe','China') and phaseno=4;
call sr_move_queue(48);
Select * From sv_current_orders where gameno=48 and powername in ('Africa','Europe','China') and phaseno=4;

-- Ground OK, no new retaliation, new territory
call sr_4_attack_set(48, Case When Length('EURO')=4 Then 'Land' Else 'Sea' End, 'Africa', 'Bay of Biscay', 'Iberia');
update sp_orders set order_code='Orders processed' Where order_code='Orders processing';
Select * From sv_current_orders where gameno=48 and powername in ('Africa','Europe','China') and phaseno=4;
call sr_move_queue(48);
-- Call sr_4_attack_set(48,'Ground','Africa','Iraq','Iran');

-- Check vs Pirates
call sr_4_attack_set(48, 'Sea', null, 'Mediterranean Sea', 'Eastern Europe');
update sp_orders set order_code='Orders processed' Where order_code='Orders processing';
Select * From sv_current_orders where gameno=48 and powername in ('Africa','Europe','China') and phaseno=4;
call sr_move_queue(48);

-- Look at the results
Select * From sv_current_orders where gameno=48 and powername in ('Africa','Europe','China') and phaseno=4;
*/
