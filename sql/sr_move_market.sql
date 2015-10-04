use asupcouk_asup;
Drop procedure if exists sr_move_market;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_move_market` (sr_gameno INT, sr_resource VARCHAR(10), sr_amount INT)
BEGIN
sproc:BEGIN

-- Procedure to change market value of a resource
-- $Id: sr_move_market.sql 242 2014-07-13 13:48:48Z paul $
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;

-- Check game number
If sr_gameno not in (Select gameno From sp_game Where phaseno != 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_MOVE_MARKET", Concat("<FAIL><Reason>Invalid game</Reason><Value>",sr_gameno,"</Value></FAIL>"));
    Leave sproc;
    End If;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check resource value
If sr_resource not in ('MINERALS','OIL','GRAIN') Then
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, "SR_MOVE_MARKET", Concat("<FAIL><Reason>Invalid Resource</Reason><Value>",sr_resource,"</Value></FAIL>"));
    Leave sproc;
    End If;

-- Get values before update
Set @max_value = (Select Max(market_level) From sp_prices);
Set @sr_rl = (Select Concat(sr_resource,'_level'));
Set @sql_upd1 = Concat("Select ",@sr_rl," Into @old_value From sp_market Where gameno=",sr_gameno);
Prepare sql_upd1 From @sql_upd1;
Execute sql_upd1;
Deallocate Prepare sql_upd1;

-- Get new value
Set @new_value = Least(@max_value, Greatest (1, @old_value+sr_amount));

Set @sql_upd = Concat("Update sp_market Set ",@sr_rl,"=? Where gameno=",sr_gameno);
Prepare sql_upd From @sql_upd;
Execute sql_upd Using @new_value;
Deallocate Prepare sql_upd;

IF @sr_debug = 'X' THEN 
	Select sr_resource, @max_value, @old_value, sr_amount, @new_value; 
END IF;

Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
 Values (sr_gameno, sr_turnno, sr_phaseno, "SR_MOVE_MARKET", Concat("<SUCCESS><Resource>",sr_resource,"</Resource>"
                                                                             ,"<MaxValue>",@max_value,"</MaxValue>"
                                                                             ,"<OldValue>",@old_value,"</OldValue>"
                                                                             ,"<Change>",sr_amount,"</Change>"
                                                                             ,"<NewValue>",@new_value,"</NewValue>"
                                                                     ,"</SUCCESS>"
                                                                     )
        );
/* */
End sproc;
END
$$

Delimiter ;

/*
Update sp_market Set minerals_level=10 Where gameno=48;
Delete From sp_old_orders;

Call sr_move_market(99,'minerals',-3);
Call sr_move_market(48,'oilx',99);
Call sr_move_market(220,'minerals',2);
Call sr_move_market(48,'minerals',-2);

Select * from sp_old_orders;
*/