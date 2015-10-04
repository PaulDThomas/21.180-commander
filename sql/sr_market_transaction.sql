use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

drop table if exists sv_resources;
drop view if exists sv_resources;
create view sv_resources as
select gameno, powername, userno, "MINERALS" as resource, minerals as resource_value, max_minerals as resource_max from sp_resource
union
select gameno, powername, userno, "OIL" as resource, oil as resource_value, max_oil as resource_max from sp_resource
union
select gameno, powername, userno, "GRAIN" as resource, grain as resource_value, max_grain as resource_max from sp_resource
;

drop table if exists sv_market_prices;
drop view if exists sv_market_prices;
create
view sv_market_prices as
Select gameno
       ,"MINERALS" as resource
       ,price
From sp_market
Left Join sp_prices On minerals_level=market_level
UNION
Select gameno
       ,"OIL" as resource
       ,price
From sp_market
Left Join sp_prices On oil_level=market_level
UNION
Select gameno
       ,"GRAIN" as resource
       ,price
From sp_market
Left Join sp_prices On grain_level=market_level
;

Drop procedure if exists sr_market_transaction;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_market_transaction` (sr_gameno INT, sr_powername CHAR(16), sr_action CHAR(4), sr_resource CHAR(8), sr_amount INT)
BEGIN
sproc:BEGIN

DECLARE procname TEXT DEFAULT "SR_MARKET_TRANSACTION";
DECLARE sr_transact TEXT;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_ft TEXT;
DECLARE sr_available INT DEFAULT 0;
DECLARE sr_max_amount INT DEFAULT 0;
DECLARE sr_end_amount INT DEFAULT 0;
DECLARE sr_start_cash INT DEFAULT 0;
DECLARE sr_end_cash INT DEFAULT 0;
DECLARE sr_transaction_value INT DEFAULT 0;
DECLARE sr_new_price INT DEFAULT 0;
DECLARE sr_siege CHAR(1);

-- Check action
Set sr_transact = Upper(sr_action);
IF sr_transact not in ('SELL','BUY') THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, procname, Concat("<FAIL><Reason>Invalid action</Reason><Action>",sr_action,"</Action></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check game and phase
IF (sr_transact='SELL' and sr_gameno not in (Select gameno From sp_game Where phaseno=3))
   or (sr_transact='BUY' and sr_gameno not in (Select gameno From sp_game Where phaseno=6))
 THEN
    Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_turnno, sr_phaseno, procname
           ,Concat("<FAIL><Reason>Invalid game or phase</Reason>"
                  ,sf_fxml("Game",sr_gameno)
                  ,sf_fxml("Transaction",sr_transact)
                  ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select siege Into sr_siege From sp_game Where gameno=sr_gameno;

-- Check resource
Set sr_resource = Upper(sr_resource);
IF sr_resource not in ('MINERALS','OIL','GRAIN') THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, procname, Concat("<FAIL><Reason>Invalid resource</Reason><Resource>",sr_resource,"</Resource></FAIL>"));
    LEAVE sproc;
END IF;

-- Check positive amount
IF sr_amount < 1 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, procname
           ,Concat("<FAIL><Reason>Invalid amount</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("Transaction",sr_transact)
                  ,sf_fxml("Resource",sr_resource)
                  ,sf_fxml("Amount",sr_amount)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;
Set sr_amount=Case When sr_transact='SELL' Then -sr_amount Else sr_amount End;

-- Check power name
IF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N') THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, procname, Concat("<FAIL><Reason>Invalid powername</Reason><PowerName>",sr_powername,"</PowerName></FAIL>"));
    LEAVE sproc;
END IF;

-- Get variables from resource view
Select userno, resource_value, resource_max
Into sr_userno, sr_available, sr_max_amount
From sv_resources
Where gameno=sr_gameno
 and powername=sr_powername
 and resource=sr_resource
;
Select price*sr_amount Into sr_transaction_value From sv_market_prices Where gameno=sr_gameno and resource=sr_resource;
Select cash Into sr_start_cash From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Check right power is processing
IF sr_userno not in (Select userno
                     From sp_orders
                     Where gameno=sr_gameno
                      and turnno=sr_turnno
                      and phaseno=sr_phaseno
                      and ordername='ORDSTAT'
                      and order_code in ('Waiting for orders','Orders processed')) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, procname
           ,Concat("<FAIL><Reason>Invalid power to process</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("Transaction",sr_transact)
                  ,sf_fxml("Resource",sr_resource)
                  ,sf_fxml("Amount",sr_amount)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check market is available
IF @sr_debug != 'N' THEN
	Select sr_siege, Count(*) From sv_trading_partners Where gameno=sr_gameno and powername=sr_powername and trading_partner='Market';
END IF;
IF (sr_siege='Y') and (Select Count(*) From sv_trading_partners Where gameno=sr_gameno and powername=sr_powername and trading_partner='Market')=0 THEN
	Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
	Values (sr_gameno
			,sr_userno
			,sr_turnno
			,sr_phaseno
			,procname
            ,Concat("<FAIL><Reason>Market is not available</Reason>"
				   ,sf_fxml("Powername",sr_powername)
                   ,"</FAIL>"));
    Leave sproc;
End IF;


-- Check amounts are valid
IF sr_transact='SELL' THEN
    IF -sr_amount > sr_available THEN
        Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno
                ,sr_userno
                ,sr_turnno
                ,sr_phaseno
                ,procname
                ,Concat("<FAIL><Reason>Not enough resource available</Reason>"
                       ,sf_fxml("Powername",sr_powername)
                       ,sf_fxml("Resource",sr_resource)
                       ,sf_fxml("Amount",sr_amount)
                       ,sf_fxml("Available",sr_available)
                       ,"</FAIL>")
                );
        LEAVE sproc;
    END IF;
ELSE
    IF sr_start_cash < sr_transaction_value THEN
        Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno
                ,sr_userno
                ,sr_turnno
                ,sr_phaseno
                ,procname
                ,Concat("<FAIL><Reason>Not enough cash available</Reason>"
                       ,sf_fxml("Powername",sr_powername)
                       ,sf_fxml("Resource",sr_resource)
                       ,sf_fxml("Amount",sr_amount)
                       ,sf_fxml("TransactionValue",sr_transaction_value)
                       ,sf_fxml("Cash",sr_start_cash)
                       ,"</FAIL>")
                );
        LEAVE sproc;
    END IF;
END IF;

-- Checks passed, process transaction
-- Update market
Call sr_move_market(sr_gameno,sr_resource,sr_amount);
-- Update resource and money
Set sr_end_amount=Least(sr_max_amount,sr_available+sr_amount);
Set sr_end_cash=sr_start_cash-sr_transaction_value;
IF sr_resource = 'MINERALS' THEN
        Update sp_resource Set minerals=sr_end_amount, cash=sr_end_cash Where gameno=sr_gameno and powername=sr_powername;
ELSEIF sr_resource = 'OIL' THEN
        Update sp_resource Set oil=sr_end_amount, cash=sr_end_cash Where gameno=sr_gameno and powername=sr_powername;
ELSE
        Update sp_resource Set grain=sr_end_amount, cash=sr_end_cash Where gameno=sr_gameno and powername=sr_powername;
END IF;

-- Return new values
Select price Into sr_new_price From sv_market_prices Where gameno=sr_gameno and resource=sr_resource;
Select resource_value Into sr_end_amount From sv_resources Where gameno=sr_gameno and powername=sr_powername and resource=sr_resource;
Select cash Into sr_end_cash From sp_resource Where gameno=sr_gameno and powername=sr_powername;

Insert Into sp_old_orders (gameno, userno, ordername, order_code)
Values (sr_gameno
        ,sr_userno
        ,procname
        ,Concat("<SUCCESS><Action>",sr_transact,"</Action>"
                        ,"<Resource>",sr_resource,"</Resource>"
                        ,"<Amount>",sr_amount,"</Amount>"
                        ,"<AmountBefore>",sr_available,"</AmountBefore>"
                        ,"<AmountAfter>",sr_end_amount,"</AmountAfter>"
                        ,"<CashBefore>",sr_start_cash,"</CashBefore>"
                        ,"<CashAfter>",sr_end_cash,"</CashAfter>"
                        ,"<PriceAfter>",sr_new_price,"</PriceAfter>"
                        ,"</SUCCESS>")
        );

-- Change negatives back to positives for messages
IF sr_transact='SELL' THEN
 Set sr_transaction_value=-sr_transaction_value;
 Set sr_amount=-sr_amount;
END IF;
Set sr_transact=Case When sr_transact='BUY' Then 'bought ' Else 'sold ' End;
Set sr_ft=Case When sr_transact='bought ' Then ' from ' Else ' to ' End;
-- Write user message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno, Concat("You have ",sr_transact,sr_amount," ",sf_format(sr_resource),sr_ft,"the market for "
                                 ,sr_transaction_value,". You now have ",sr_end_amount
                                 ," ",sf_format(sr_resource)," and ",sr_end_cash,"."
                                 ));
-- Write general message
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, 0, Concat(sf_format(sr_powername)," has ",sr_transact,sr_amount," ",sf_format(sr_resource),sr_ft
                           ,"the market for ",sr_transaction_value,". "
                           ,sf_format(sr_resource)," now cost",Case When sr_resource='Minerals' Then " " Else "s "End,sr_new_price," per unit."
                           )
        );
/* */

END sproc;
END
$$

Delimiter ;

/*
Delete From sp_old_orders;
Delete From sp_message_queue;

Update sp_resource Set cash=2000, minerals=5, oil=5, grain=5 Where gameno=48;
update sp_market set minerals_level=17, oil_level=10, grain_level=2 where gameno=48;

-- Invalid Sells
-- Call sr_market_transaction(48,'Europe','sxe','oil',1);
-- Call sr_market_transaction(99,'Australia','Buy','Oil',1);
-- Call sr_market_transaction(48,'Europe','Buy','Oil',1);
-- Call sr_market_transaction(48,'Africa','Sell','Minerals',1);
-- Call sr_market_transaction(48,'Europe','Sell','nukes',1);
-- Call sr_market_transaction(48,'Europe','Sell','Oil',0);
-- Call sr_market_transaction(48,'Europe','Sell','Oil',200);

-- Invalid BUYS
-- Call sr_market_transaction(48,'Europe','Sell','Oil',1);
-- Call sr_market_transaction(48,'Europe','Buy','nukes',1);
-- Call sr_market_transaction(48,'Africa','Buy','Minerals',1);
-- Call sr_market_transaction(48,'Europe','Buy','Oil',0);
-- Call sr_market_transaction(48,'Europe','Buy','Oil',200);

Call sr_market_transaction(48,'Europe','Buy','Minerals',1);
Call sr_market_transaction(48,'Europe','Buy','Oil',1);
Call sr_market_transaction(48,'Europe','Buy','Grain',1);

Call sr_market_transaction(48,'Europe','Sell','Minerals',1);
Call sr_market_transaction(48,'Europe','Sell','Oil',1);
Call sr_market_transaction(48,'Europe','Sell','Grain',1);
-- Select * From sp_old_orders;
Select * From sp_message_queue;
*/
