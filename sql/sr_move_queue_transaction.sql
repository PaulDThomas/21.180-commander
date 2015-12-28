use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_move_queue_transaction;

DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_move_queue_transaction` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Procedure to process transaction and move to next user
-- $Id: sr_move_queue_transaction.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_TRANSACTION";
DECLARE done INT DEFAULT 0;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_sell_userno INT DEFAULT 0;
DECLARE sr_buy_userno INT DEFAULT 0;
DECLARE sr_resource TEXT;
DECLARE sr_buy_powername VARCHAR(15);
DECLARE sr_sell_powername VARCHAR(15);
DECLARE sr_price INT DEFAULT 0;
DECLARE sr_amount INT DEFAULT 0;
DECLARE sr_totalvalue INT DEFAULT 0;
DECLARE sr_accepted CHAR(1);

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno in (3,6)) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game or phase</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
Select g.turnno, g.phaseno, o.userno
 ,extractValue(order_code,'/TRANSACTION/Resource')
 ,extractValue(order_code,'/TRANSACTION/Seller')
 ,extractValue(order_code,'/TRANSACTION/Buyer')
 ,extractValue(order_code,'/TRANSACTION/Price')
 ,extractValue(order_code,'/TRANSACTION/Amount')
 ,extractValue(order_code,'/TRANSACTION/Accepted')
 ,extractValue(order_code,'/TRANSACTION/TotalValue')
Into sr_turnno, sr_phaseno, sr_userno, sr_resource, sr_sell_powername, sr_buy_powername, sr_price, sr_amount, sr_accepted, sr_totalvalue
From sp_game g, sp_orders o
Where g.gameno=sr_gameno
 and o.gameno=g.gameno
 and o.turnno=g.turnno
 and o.phaseno=g.phaseno
 and o.ordername='SR_ORDERXML'
;

IF @sr_debug != 'N' THEN
    Select "Transaction variables:", sr_turnno, sr_phaseno, sr_userno, sr_resource, sr_sell_powername, sr_buy_powername, sr_price, sr_amount, sr_accepted, sr_totalvalue;
END IF;

-- Process pass
If sr_resource='PASS' THEN
    IF @sr_debug != 'N' THEN Select "Passing"; END IF;
    Update sp_orders Set order_code='Passed' Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='ORDSTAT' and userno=sr_userno;
    call sr_move_queue(sr_gameno);
    LEAVE sproc;
END IF;

-- Set transaction user numbers
Select userno Into sr_sell_userno From sp_resource Where gameno=sr_gameno and powername=sr_sell_powername;
Select userno Into sr_buy_userno From sp_resource Where gameno=sr_gameno and powername=sr_buy_powername;

-- Send market transactions, checking is in called procedure
IF sr_buy_powername = 'MARKET' THEN
    IF @sr_debug != 'N' THEN Select *, "Before transaction" From sv_current_orders Where gameno=sr_gameno and phaseno=sr_phaseno; END IF;
    call sr_market_transaction(sr_gameno, sr_sell_powername, "SELL", sr_resource, sr_amount);
    Update sp_orders Set order_code = 'Orders processed' Where gameno = sr_gameno and userno = sr_userno and turnno = sr_turnno and phaseno = sr_phaseno and ordername = 'ORDSTAT';
    IF @sr_debug != 'N' THEN Select *, "After transaction" From sv_current_orders Where gameno=sr_gameno and phaseno=sr_phaseno; END IF;
    call sr_move_queue(sr_gameno);
ELSEIF sr_sell_powername = 'MARKET' THEN
    call sr_market_transaction(sr_gameno, sr_buy_powername, "BUY", sr_resource, sr_amount);
    Update sp_orders Set order_code = 'Orders processed' Where gameno = sr_gameno and userno = sr_userno and turnno = sr_turnno and phaseno = sr_phaseno and ordername = 'ORDSTAT';
    call sr_move_queue(sr_gameno);
ELSEIF sr_accepted = 'Y' and sr_amount*sr_price=sr_totalvalue THEN
    IF @sr_debug != 'N' THEN Select sr_gameno, sr_sell_powername, sr_buy_powername, sr_resource, sr_amount, sr_totalvalue; END IF;
    call sr_user_transaction(sr_gameno, sr_sell_powername, sr_buy_powername, sr_resource, sr_amount, sr_totalvalue);
    Update sp_orders Set order_code = 'Orders processed' Where gameno = sr_gameno and userno = sr_userno and turnno = sr_turnno and phaseno = sr_phaseno and ordername = 'ORDSTAT';
    call sr_move_queue(sr_gameno);
ELSEIF sr_accepted = 'Y' THEN
    Insert into sp_old_orders (gameno, useron, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Accept Total</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("SellPowername",sr_sell_powername)
                   ,sf_fxml("BuyPowername",sr_buy_powername)
                   ,sf_fxml("Resource",sr_resource)
                   ,sf_fxml("Price",sr_price)
                   ,sf_fxml("Amount",sr_amount)
                   ,sf_fxml("TotalValue",sr_totalvalue)
                   ,"</FAIL>")
            );
ELSEIF sr_accepted='R' and sr_phaseno=3 THEN
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_sell_userno, -1, Concat('Your offer to sell ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,' has been rejected by ',sf_format(sr_buy_powername),'.'));
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_buy_userno, 0, Concat('You have rejected an offer from ',sf_format(sr_sell_powername),' to sell ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,'.'));
    Delete From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_sell_userno and ordername='SR_ORDERXML';
ELSEIF sr_accepted='R' and sr_phaseno=6 THEN
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_buy_userno, -1, Concat('Your offer to buy ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,' has been rejected by ',sf_format(sr_sell_powername),'.'));
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_sell_userno, 0, Concat('You have rejected an offer from ',sf_format(sr_buy_powername),' to buy ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,'.'));
    Delete From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and userno=sr_buy_userno and ordername='SR_ORDERXML';
ELSEIF sr_accepted='N' and sr_phaseno=3 THEN
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_buy_userno, -1, Concat(sf_format(sr_sell_powername), ' is offering to sell you ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,'.'));
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_sell_userno, 0, Concat('You are offering to sell ',sf_format(sr_buy_powername),' ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,'.'));
    Update sp_resource Set randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10) Where gameno=sr_gameno and powername in (sr_sell_powername, sr_buy_powername);
ELSEIF sr_accepted='N' and sr_phaseno=6 THEN
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_sell_userno, -1, Concat(sf_format(sr_buy_powername), ' is offering to buy ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,' from you.'));
    Insert Into sp_messages (gameno, userno, to_email, message) values (sr_gameno, sr_buy_userno, 0, Concat('You are offering to buy ',sr_amount,' ',sf_format(sr_resource),' for ',sr_totalvalue,' from ',sf_format(sr_sell_powername),'.'));
    Update sp_resource Set randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10) Where gameno=sr_gameno and powername in (sr_sell_powername, sr_buy_powername);
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;
/*
Delete From sp_messages;
Delete From sp_old_orders;
Delete From sp_orders;
Update sp_resource Set mia=0 Where gameno=48;
Update sp_game Set turnno=5, phaseno=3 Where gameno=48;

INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,3,'ORDSTAT','In queue - 1');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,5,3,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,3,'ORDSTAT','In queue - 2');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,5,3,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,5,3,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,5,3,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,5,3,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,3,'ORDSTAT','Waiting for orders');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,5,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,5,5,'ORDSTAT','Passed');

INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,5,4,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,5,6,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,5,6,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,5,6,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,6,'ORDSTAT','First');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,5,6,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,6,'ORDSTAT','In queue - 2');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,6,'ORDSTAT','In queue - 1');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,5,6,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3389,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3239,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3244,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3426,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,7,'ORDSTAT','Passed');
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3448,5,7,'ORDSTAT','Passed');

INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3227,5,3,'SR_ORDERXML'
 ,'<TRANSACTION><Resource>pass</Resource><Seller>Europe</Seller><Buyer>Market</Buyer><Price>0</Price><Amount>0</Amount><TotalValue>0</TotalValue><Accepted>N</Accepted></TRANSACTION>');

-- Check game;
call sr_move_queue_transaction(2);

-- Process pass
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Sell Pass' From sv_current_orders Where gameno=48 and phaseno=3;

-- Sell to the market
Update sp_resource Set minerals=10, cash=0 Where gameno=48 and powername='Africa';
Update sp_market Set minerals_level=10 Where gameno=48;
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,3,'SR_ORDERXML'
 ,'<TRANSACTION><Resource>minerals</Resource><Seller>Africa</Seller><Buyer>Market</Buyer><Price>0</Price><Amount>5</Amount><TotalValue>0</TotalValue><Accepted>N</Accepted></TRANSACTION>');
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Sell Market' From sv_current_orders Where gameno=48 and phaseno=3;

-- Sell to the other power - offer
Update sp_resource Set minerals=6, cash=200 Where gameno=48 and powername in ('North America','Europe');
Update sp_market Set minerals_level=10 Where gameno=48;
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,3,'SR_ORDERXML'
 ,'<TRANSACTION><Resource>minerals</Resource><Seller>North America</Seller><Buyer>Europe</Buyer><Price>50</Price><Amount>2</Amount><TotalValue>100</TotalValue><Accepted>N</Accepted></TRANSACTION>');
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Sell Offer' From sv_current_orders Where gameno=48 and phaseno=3;

-- Sell to other power - reject
Update sp_orders Set order_code = UpdateXML(order_code,'//Accepted',sf_fxml('Accepted','R')) Where gameno=48 and userno=3417 and ordername='SR_ORDERXML';
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Sell Reject' From sv_current_orders Where gameno=48 and phaseno=3;

-- Sell to other power - accept
Update sp_orders Set order_code = UpdateXML(order_code,'//Accepted',sf_fxml('Accepted','Y')) Where gameno=48 and userno=3417 and ordername='SR_ORDERXML';
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Sell Accept' From sv_current_orders Where gameno=48;

-- Move to Buy
Update sp_orders Set order_code='Passed' Where gameno=48 and phaseno<6;
Call sr_move_queue(48);

-- Buy from market
Update sp_resource Set cash=1000 Where gameno='48' and powername='Africa';
Update sp_market Set minerals_level=1 Where gameno=48;
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3238,5,6
,'SR_ORDERXML'
 ,'<TRANSACTION><Resource>minerals</Resource><Seller>Market</Seller><Buyer>Africa</Buyer><Price>1</Price><Amount>5</Amount><TotalValue>5</TotalValue><Accepted>N</Accepted></TRANSACTION>');
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Buy Market' From sv_current_orders Where gameno=48 and phaseno=6;


-- Sell to the other power - offer
Update sp_resource Set minerals=6, cash=200 Where gameno=48 and powername in ('North America','Europe');
Update sp_market Set minerals_level=10 Where gameno=48;
INSERT INTO `sp_orders` (`gameno`, `userno`, `turnno`, `phaseno`, `ordername`, `order_code`) VALUES (48,3417,5,6,'SR_ORDERXML'
 ,'<TRANSACTION><Resource>minerals</Resource><Seller>Europe</Seller><Buyer>North America</Buyer><Price>5</Price><Amount>2</Amount><TotalValue>10</TotalValue><Accepted>N</Accepted></TRANSACTION>');
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Buy Offer' From sv_current_orders Where gameno=48 and phaseno=6;

-- Sell to other power - reject
Update sp_orders Set order_code = UpdateXML(order_code,'//Accepted',sf_fxml('Accepted','R')) Where gameno=48 and userno=3417 and ordername='SR_ORDERXML';
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Buy Reject' From sv_current_orders Where gameno=48 and phaseno=6;

-- Sell to other power - accept
Update sp_orders Set order_code = UpdateXML(order_code,'//Accepted',sf_fxml('Accepted','Y')) Where gameno=48 and userno=3417 and ordername='SR_ORDERXML';
Set @sr_debug='N';
call sr_move_queue_transaction(48);
Select *,'After Buy Accept' From sv_current_orders Where gameno=48;


Select * From sv_current_orders Where gameno=48;
select * From sp_messages where gameno=48;

Select g.turnno, g.phaseno, o.userno
 ,upper(extractValue(order_code,'/TRANSACTION/Resource'))
 ,upper(extractValue(order_code,'/TRANSACTION/Seller'))
 ,upper(extractValue(order_code,'/TRANSACTION/Buyer'))
 ,upper(extractValue(order_code,'/TRANSACTION/Price'))
 ,upper(extractValue(order_code,'/TRANSACTION/Amount'))
 ,upper(extractValue(order_code,'/TRANSACTION/Accepted'))
 ,upper(extractValue(order_code,'/TRANSACTION/TotalValue'))
From sp_game g, sp_orders o
Where g.gameno=48
 and o.gameno=g.gameno
 and o.turnno=g.turnno
 and o.phaseno=g.phaseno
 and o.ordername='SR_ORDERXML'
;
*/