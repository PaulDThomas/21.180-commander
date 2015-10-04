/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
use asupcouk_asup;
Drop procedure if exists SR_USER_transaction;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_user_transaction` (sr_gameno INT, sr_sell_power CHAR(16), sr_buy_power CHAR(16), sr_resource CHAR(50), sr_amount INT, sr_transaction_value INT)
BEGIN
sproc:BEGIN

-- $Id: sr_user_transaction.sql 244 2014-07-13 16:44:49Z paul $
DECLARE sr_siege CHAR(1);

-- Check game and phase
If sr_gameno not in (Select gameno From sp_game Where phaseno in (3,6)) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid game or phase</Reason><Gameno>",sr_gameno,"</Gameno></FAIL>"));
    Leave sproc;
End If;
Select siege Into sr_siege From sp_game Where gameno=sr_gameno;
Set @gameno = sr_gameno;
Set @phaseno = (Select phaseno From sp_game Where gameno=@gameno);

-- Check selling power name
If sr_sell_power not in (Select powername From sp_resource Where gameno=@gameno and dead='N') Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid selling powername</Reason><SellingPowername>",sr_sell_power,"</SellingPowername></FAIL>"));
    Leave sproc;
End If;
Set @sell_power=sr_sell_power;
Set @sell_userno=(Select userno From sp_resource Where gameno=@gameno and powername=@sell_power);
If @phaseno=3 and @sell_userno not in (Select userno From sp_orders Where gameno=@gameno and order_code in ('Waiting for orders','Orders processed')) Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid selling user, not their turn</Reason><SellingPowername>",sr_sell_power,"</SellingPowername><SellingUserno>",@sell_userno,"</SellingUserno></FAIL>"));
    Leave sproc;
End If;

-- Check buying power name
If sr_buy_power not in (Select powername From sp_resource Where gameno=@gameno and dead='N') Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid buying powername</Reason><BuyingPowername>",sr_buy_power,"</BuyingPowername></FAIL>"));
    Leave sproc;
End If;
Set @buy_power=sr_buy_power;
Set @buy_userno=(Select userno From sp_resource Where gameno=@gameno and powername=@buy_power);
If @phaseno=6 and @buy_userno not in (Select userno From sp_orders Where gameno=@gameno and order_code in ('Waiting for orders','Orders processed')) Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid buying user, not their turn</Reason><BuyingPowername>",@buy_power,"</BuyingPowername><BuyingUserno>",@buy_userno,"</BuyingUserno></FAIL>"));
    Leave sproc;
End If;
Set @current_userno=Case @phaseno When 3 Then @selluserno Else @buyuserno End;

-- Check resource
Set @resource = Upper(sr_resource);
If @resource not in ('MINERALS','OIL','GRAIN','LSTARS','NUKES','KSATS','NEUTRON'
                    ,'MAX_MINERALS','MAX_OIL','MAX_GRAIN','RESOURCE_TECH'
                    ,'LAND_TECH','WATER_TECH','STRATEGIC_TECH','ESPIONAGE_TECH') Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid resource</Reason><Resource>",sr_resource,"</Resource></FAIL>"));
    Leave sproc;
End If;

-- Check positive amount
If sr_amount < 1 Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Negative transaction amount</Reason><Amount>",sr_amount,"</Amount></FAIL>"));
    Leave sproc;
End If;
Set @amount=sr_amount;

-- Check positive cash
If sr_transaction_value < 0 Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Negative transaction value</Reason><Value>",sr_transaction_value,"</Value></FAIL>"));
    Leave sproc;
End If;
Set @transaction_value=sr_transaction_value;

-- Check trade is possible
IF @sr_debug != 'N' THEN
	Select sr_siege, Count(*) From sv_trading_partners Where gameno=sr_gameno and powername=sr_sell_power and trading_partner=sr_buy_power;
END IF;
IF (sr_siege='Y') and (Select Count(*) From sv_trading_partners Where gameno=sr_gameno and powername=sr_sell_power and trading_partner=sr_buy_power)=0 THEN
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Invalid trading partners</Reason>"
                                                             ,sf_fxml("BuyingPowername",@buy_power)
                                                             ,sf_fxml("SellingPowername",@sell_power)
                                                             ,"/FAIL>"));
    Leave sproc;
End IF;


-- Get initial resource values
If @resource like '%TECH' Then
    Set @sql_chk1=Concat("Select ",@resource,", cash Into @buy_start_resource, @buy_start_cash From sp_resource Where gameno=",@gameno," and userno=",@buy_userno);
    Set @buy_max_resource=5;
    If @resource='ESPIONAGE_TECH' Then
        Set @buy_max_resource=20;
    End If;
ElseIf @resource in ('MINERALS','OIL','GRAIN') Then
    Set @sql_chk1=Concat("Select ",@resource,", cash, max_",@resource," Into @buy_start_resource, @buy_start_cash, @buy_max_resource From sp_resource Where gameno=",@gameno," and userno=",@buy_userno);
Else
    Set @sql_chk1=Concat("Select ",@resource,", cash Into @buy_start_resource, @buy_start_cash From sp_resource Where gameno=",@gameno," and userno=",@buy_userno);
    Set @buy_max_resource=99;
End If;
Prepare sql_chk1 From @sql_chk1;
Execute sql_chk1;
Deallocate Prepare sql_chk1;

Set @sql_chk2=Concat("Select ",@resource,", cash Into @sell_start_resource, @sell_start_cash From sp_resource Where gameno=",@gameno," and userno=",@sell_userno);
Prepare sql_chk2 From @sql_chk2;
Execute sql_chk2;
Deallocate Prepare sql_chk2;

-- Print initial Resources
IF @sr_debug!='N' THEN
    Select @gameno, @resource, @amount, @sell_userno, @sell_start_resource, @sell_start_cash, @buy_userno, @buy_start_resource, @buy_start_cash, @buy_max_resource;
END IF;

-- Check initial resources
If @sell_start_resource < @amount Then
    Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
     Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Seller does not have enough resource</Reason>"
                                                             ,"<Seller>",@sell_userno,"</Seller>"
                                                             ,"<Resource>",@resource,"</Resource>"
                                                             ,"<AvailableResource>",@sell_start_resource,"</AvailableResource>"
                                                             ,"<TransactionAmount>",@amount,"</TransactionAmount>"
                                                             ,"</FAIL>"));
    Leave sproc;
ElseIf @buy_start_cash < @transaction_value Then
     Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
      Values (@gameno, @phaseno, "SR_USER_TRANSACTION", Concat("<FAIL><Reason>Buyer does not have enough cash</Reason>"
                                                              ,"<Buyer>",@buy_userno,"</Buyer>"
                                                              ,"<AvailableCash>",@buy_start_cash,"</AvailableCash>"
                                                              ,"<TransactionValue>",@transaction_value,"</TransactionValue>"
                                                              ,"</FAIL>")
             );
     Leave sproc;
End If;

-- Checks passed, process transaction
-- Update resource and money
If @resource like '%TECH' Then
    Set @sell_end_resource=@sell_start_resource;
Else
    Set @sell_end_resource=@sell_start_resource-@amount;
End If;
Set @sell_end_cash=@sell_start_cash+@transaction_value;

If @resource like '%TECH' Then
    Set @buy_end_resource=Least(Greatest(@amount,@buy_start_resource),@buy_max_resource);
Else
    Set @buy_end_resource=Least(@buy_start_resource+@amount,@buy_max_resource);
End If;
Set @buy_end_cash=@buy_start_cash-@transaction_value;

Set @sql_upd1 = Concat("Update sp_resource Set ",@resource,"= ?, cash = ? Where gameno = ? and userno = ?");
-- Show query to run
IF @sr_debug!='N' THEN Select @sql_upd1, @sell_end_resource, @sell_end_cash, @gameno, @sell_userno, @sell_end_resource, @sell_end_cash, @gameno, @sell_userno; END IF;
Prepare sql_upd1 From @sql_upd1;
Execute sql_upd1 Using @sell_end_resource, @sell_end_cash, @gameno, @sell_userno;
Execute sql_upd1 Using @buy_end_resource, @buy_end_cash, @gameno, @buy_userno;
Deallocate Prepare sql_upd1;

-- Return new values
Set @sql_chk3 = Concat("Select ",@resource,", cash Into @after_resource,@after_cash From sp_resource Where gameno=? and userno=?");
Prepare sql_chk3 From @sql_chk3;
Execute sql_chk3 Using @gameno, @sell_userno;
Set @sell_after_resource=@after_resource;
Set @sell_after_cash=@after_cash;
Execute sql_chk3 Using @gameno, @buy_userno;
Set @buy_after_resource=@after_resource;
Set @buy_after_cash=@after_cash;
Deallocate Prepare sql_chk3;

Insert Into sp_old_orders (gameno, phaseno, ordername, order_code)
 Values (@gameno, @phaseno
        ,"SR_USER_TRANSACTION"
        ,Concat("<SUCCESS>"
                  ,"<Resource>",@resource,"</Resource>"
                  ,"<Amount>",@amount,"</Amount>"
                  ,"<TransactionValue>",@transaction_value,"</TransactionValue>"
                  ,"<Seller>",@sell_power," ",@sell_userno,"</Seller>"
                  ,"<SellerResourceBefore>",@sell_start_resource,"</SellerResourceBefore>"
                  ,"<SellerResourceAfter>",@sell_after_resource,"</SellerResourceAfter>"
                  ,"<SellerCashBefore>",@sell_start_cash,"</SellerCashBefore>"
                  ,"<SellerCashAfter>",@sell_after_cash,"</SellerCashAfter>"
                  ,"<Buyer>",@buy_power," ",@buy_userno,"</Buyer>"
                  ,"<BuyerResourceBefore>",@Buy_start_resource,"</BuyerResourceBefore>"
                  ,"<BuyerResourceAfter>",@Buy_after_resource,"</BuyerResourceAfter>"
                  ,"<BuyerCashBefore>",@Buy_start_cash,"</BuyerCashBefore>"
                  ,"<BuyerCashAfter>",@Buy_after_cash,"</BuyerCashAfter>"
                ,"</SUCCESS>")
        );

Insert Into sp_message_queue (gameno, userno, message, to_email)
 Values (@gameno, @sell_userno, Concat("You have sold ",@amount," ",sf_format(@resource)," to "
                                      ,@buy_power," for ",@transaction_value
                                      ,". You now have ",@sell_after_resource," ",sf_format(@resource)
                                      ," and ",@sell_after_cash,"."
                                      )
        ,-1);

Insert Into sp_message_queue (gameno, userno, message, to_email)
 Values (@gameno, @buy_userno,  Concat("You have bought ",@amount," ",sf_format(@resource)," from "
                                      ,@sell_power," for ",@transaction_value
                                      ,". You now have ",@buy_after_resource," ",sf_format(@resource)
                                      ," and ",@buy_after_cash,"."
                                      )
        ,-1);

IF @sr_debug!='N' THEN
    select * from sp_message_queue;
END IF;

END sproc;
END
$$

Delimiter ;
/*
-- Delete From sp_old_orders;
-- Delete From sp_messages;
-- Delete From sp_message_queue;
-- Update sp_resource Set land_tech=4, cash=800, max_oil=15 Where gameno=38 and powername='North America';
-- Update sp_resource Set cash=2000 Where gameno=38 and powername='Russia';
-- Update sp_resource Set oil=10, cash=800, max_oil=12 Where gameno=21 and powername='Africa';
-- Update sp_resource Set dead='Y' Where gameno=21 and powername='Europe';


-- Call sr_user_transaction(38,'North America','Russia','land_tech',4,333);

-- Select * From sp_old_orders Order By order_uts Desc;
-- Select * From sp_message_queue;
*/
