use asupcouk_asup;
Drop procedure if exists sr_acquire_comp;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE  asupcouk_asup . sr_acquire_comp  (sr_gameno INT, sr_cardno INT, sr_powername TEXT)
BEGIN
sproc:BEGIN

-- Create list of companies to purchase
-- $Id: sr_acquire_comp.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_ACQUIRE_COMP";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_cash INT DEFAULT 0;
DECLARE sr_terrname TEXT;
DECLARE sr_terrno TEXT;
DECLARE sr_res_name TEXT;
DECLARE sr_res_amount INT DEFAULT 0;
DECLARE sr_major INT DEFAULT 0;
DECLARE sr_minor INT DEFAULT 0;
DECLARE sr_terruser INT DEFAULT 0;
DECLARE sr_cost INT DEFAULT 0;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=7)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check Superpower is valid
IF sr_powername != (Select powername From sp_resource r, sp_orders o Where r.gameno=sr_gameno and dead='N' and o.gameno=r.gameno and o.userno=r.userno and o.ordername='ORDSTAT' and o.order_code='Waiting for orders') THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid Superpower")
                                  ,sf_fxml("Game",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("CardNo",sr_cardno)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;
Select userno, cash Into sr_userno, sr_cash From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Check card is available
IF (Select extractValue(order_code,Concat("/COMPANIES/CardNo[text()='",sr_cardno,"']")) From sp_orders Where gameno=sr_gameno and ordername='SR_ACOMP') = '' THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid Company number")
                                  ,sf_fxml("Game",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("CardNo",sr_cardno)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;
Select terrname, b.terrno, major, minor, b.userno as terruser, res_amount, res_name
Into sr_terrname, sr_terrno, sr_major, sr_minor, sr_terruser, sr_res_amount, sr_res_name
From sp_res_cards rc, sp_board b, sp_places p
Where rc.cardno=sr_cardno
 and rc.terrno=b.terrno
 and p.terrno=rc.terrno
 and b.gameno=sr_gameno
;
IF @sr_debug!='N' THEN Select sr_terrname, sr_major, sr_minor, sr_terruser; END IF;

-- Check card can be bought
IF sr_terruser > 0 and sr_terruser != sr_userno THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid Company location")
                                  ,sf_fxml("Game",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("Userno",sr_userno)
                                  ,sf_fxml("CardNo",sr_cardno)
                                  ,sf_fxml("Terrname",sr_terrname)
                                  ,sf_fxml("TerrUser",sr_terruser)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Calculate cash amount
Set sr_cost = 100*(sr_userno!=sr_terruser)*(10+5*sr_major+sr_minor)+200*sr_res_amount;
IF @sr_debug!='N' THEN Select "Company cost:", sr_cost; END IF;

-- Check funds are available
IF sr_cash < sr_cost THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Not enough cash")
                                  ,sf_fxml("Game",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("Userno",sr_userno)
                                  ,sf_fxml("CardNo",sr_cardno)
                                  ,sf_fxml("CashAvailable",sr_cash)
                                  ,sf_fxml("Cost",sr_cost)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Change company
Update sp_cards Set userno=sr_userno Where gameno=sr_gameno and cardno=sr_cardno;

-- Take territory
Call sr_take_territory(sr_gameno,sr_terrname,sr_powername,sr_major,sr_minor);

-- Remove company from available list
Update sp_orders Set order_code=updateXML(order_code,Concat("/COMPANIES/CardNo[text()='",sr_cardno,"']"),"") Where gameno=sr_gameno and ordername='SR_ACOMP';
Update sp_orders Set order_code=updateXML(order_code,"/COMPANIES/n",sf_fxml('n',extractValue(order_code,'Count(//CardNo)'))) Where gameno=sr_gameno and ordername='SR_ACOMP';

-- Remove cash
Update sp_resource Set cash=cash-sr_cost Where gameno=sr_gameno and powername=sr_powername;

-- Add message
Insert Into sp_messages (gameno, userno, message)
Values (sr_gameno, sr_userno, Concat("You have acquired ",sr_res_name," in ",sr_terrname," for ",sr_cost,".  You have ",sr_cash-sr_cost," left."));
Insert Into sp_messages (gameno, userno, message)
Values (sr_gameno, 0, Concat(sr_powername," has acquired ",sr_res_name," in ",sr_terrname,"."));

-- Change status
Update sp_orders Set order_code='Orders processed' Where gameno=sr_gameno and userno=sr_userno and ordername='ORDSTAT';

-- Add log entry
Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
 Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
        ,Concat(sf_fxml("SUCCESS",
                        Concat(sf_fxml("Game",sr_gameno)
                              ,sf_fxml("Powername",sr_powername)
                              ,sf_fxml("Userno",sr_userno)
                              ,sf_fxml("CardNo",sr_cardno)
                              ,sf_fxml("Terrname",sr_terrname)
                              ,sf_fxml("TerrUserNo",sr_terruser)
                              ,sf_fxml("ResName",sr_res_name)
                              ,sf_fxml("Cash",sr_cash)
                              ,sf_fxml("Cost",sr_cost)
                              ,sf_fxml("CashAfter",sr_cash-sr_cost)
                              )
                        )
                )
        );

-- Move queue
call sr_move_queue(sr_gameno);

-- /* */
END sproc;
END
$$

Delimiter ;
/*
Set @sr_debug='N';

-- Set board
Call sr_take_territory(48,'Romania','Warlord',0,1);
Call sr_take_territory(48,'Greece','Neutral',0,0);
Call sr_take_territory(48,'Poland','Africa',0,3);
Call sr_take_territory(48,'Iberia','Europe',1,1);

-- Clear tables
Delete from sp_orders Where gameno=48;
Delete from sp_old_orders;
Delete from sp_messages;

-- Set game/orders
Update sp_game Set turnno=3, phaseno=7, process=null Where Gameno=48;
Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, 3, 7, 'ORDSTAT', 'Passed' From sp_resource Where gameno=48 and dead='N';
Update sp_orders Set order_code='Waiting for orders' Where gameno=48 and userno=3227 and phaseno=7;
Update sp_resource Set cash=1000,loan=0 Where gameno=48 and powername='Europe';

-- Add cards from Greece, Iberia, Poland, Romania
Update sp_cards Set userno=0 Where gameno=48 and cardno in (52,14,41,69);
Insert Into sp_orders (gameno, turnno, phaseno, ordername, order_code)
Values (48, 3, 7, 'SR_ACOMP', sf_fxml('COMPANIES',Concat(sf_fxml('n',4),sf_fxml('CardNo',52),sf_fxml('CardNo',14),sf_fxml('CardNo',41),sf_fxml('CardNo',69))));
Call sr_move_queue_comp(48);

-- Check game
-- call sr_acquire_comp(-1,52,'Europe');

-- Check Superpower
-- call sr_acquire_comp(48,52,'Arabia');

-- Check cardno
-- call sr_acquire_comp(48,-1,'Europe');

-- OK card, wrong territory
-- call sr_acquire_comp(48,41,'Europe');

-- Not enough cash
-- call sr_acquire_comp(48,52,'Europe');

-- Own territory card, success
-- Call sr_acquire_comp(48,14,'Europe');

-- Other territory card, success
Call sr_change_loan(48,'Europe',2000);
Call sr_acquire_comp(48,69,'Europe');

Select * from sp_messages;
*/