use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

Drop procedure if exists sr_transfer_cash;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_transfer_cash` (sr_gameno INT, sr_powername_from VARCHAR(15), sr_powername_to VARCHAR(15), sr_amount INT)
BEGIN
sproc:BEGIN

-- Declare variables
-- $Id: sr_transfer_cash.sql 323 2015-12-19 21:25:27Z paul $
DECLARE proc_name CHAR(32) Default "SR_TRANSFER_CASH";
DECLARE sr_userno_from INT Default 0;
DECLARE sr_userno_to INT Default 0;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_pct INT DEFAULT 0;
DECLARE sr_current_cash_from INT Default 0;
DECLARE sr_current_cash_to INT Default 0;
DECLARE sr_current_out INT Default 0;
DECLARE sr_current_in INT Default 0;
DECLARE sr_cash_avail INT Default 0;
DECLARE sr_new_cash_from INT Default 0;
DECLARE sr_new_cash_to INT Default 0;

-- Check game number
IF sr_gameno not in (Select gameno From sp_game Where phaseno != 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game</Reason><Value>",sr_gameno,"</Value></FAIL>"));
    LEAVE sproc;
    END IF;
Select turnno, phaseno, liquid_asset_percent Into sr_turnno, sr_phaseno, sr_pct From sp_game Where gameno=sr_gameno;

-- Check powername
IF Upper(sr_powername_from) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Power From</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername_from)
                   ,"</FAIL>")
            );
    LEAVE sproc;
ELSEIF Upper(sr_powername_to) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N' and powername != sr_powername_from) THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Power To</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername_to)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Get game information
Select userno, cash, cash_transferred_in, cash_transferred_out Into sr_userno_from, sr_current_cash_from, sr_current_in, sr_current_out From sp_resource Where gameno=sr_gameno and powername=sr_powername_from;
Select userno, cash Into sr_userno_to, sr_current_cash_to From sp_resource Where gameno=sr_gameno and powername=sr_powername_to;

-- Check something is happening
IF sr_amount<=0 THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid transfer amount</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("PowernameFrom",sr_powername_from)
                   ,sf_fxml("PowernameTo",sr_powername_to)
                   ,sf_fxml("Amount",sr_amount)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Check cash is available
Set sr_cash_avail = Floor( (sr_current_cash_from-sr_current_in+sr_current_out) * sr_pct/100 + sr_current_in - sr_current_out);
IF sr_amount > sr_cash_avail THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Excessive transfer amount</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("PowernameFrom",sr_powername_from)
                   ,sf_fxml("PowernameTo",sr_powername_to)
                   ,sf_fxml("Amount",sr_amount)
                   ,sf_fxml("CurrentCash",sr_current_cash_from)
                   ,sf_fxml("TransferredOut",sr_current_out)
                   ,sf_fxml("TransferredIn",sr_current_in)
                   ,sf_fxml("CashAvailable",sr_cash_avail)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Process transfer to
Update sp_resource
Set cash=cash+sr_amount, cash_transferred_in=cash_transferred_in + sr_amount, randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10)
Where gameno=sr_gameno
 and powername=sr_powername_to
;
-- Get new details
Select cash Into sr_new_cash_to From sp_resource Where gameno=sr_gameno and powername=sr_powername_to;

-- Process transfer from
Update sp_resource
Set cash=cash-sr_amount, cash_transferred_out=cash_transferred_out + sr_amount, randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10)
Where gameno=sr_gameno
 and powername=sr_powername_from
;
-- Get new details
Select cash Into sr_new_cash_from From sp_resource Where gameno=sr_gameno and powername=sr_powername_from;


-- Set success message
Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
 Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
        ,Concat("<SUCCESS><Action>Transfer Cash</Action>"
               ,sf_fxml("PowernameFrom",sr_powername_from)
               ,sf_fxml("PowernameTo",sr_powername_to)
               ,sf_fxml("Amount",sr_amount)
               ,sf_fxml("CurrentCash",sr_current_cash_from)
               ,sf_fxml("TransferredOut",sr_current_out)
               ,sf_fxml("TransferredIn",sr_current_in)
               ,sf_fxml("CashAvailable",sr_cash_avail)
               ,sf_fxml("NewCashFrom",sr_new_cash_from)
               ,sf_fxml("NewCashTo",sr_new_cash_to)
               ,"</SUCCESS>")
    );

-- Send messages
Insert Into sp_messages (gameno, userno, message)
 Values (sr_gameno, sr_userno_from
        ,Concat("You have transferred ",sr_amount," cash to ",sr_powername_to,". You now have ",sr_new_cash_from,".")
        );
Insert Into sp_messages (gameno, userno, to_email, message)
 Values (sr_gameno, sr_userno_to, 1
        ,Concat("You have received ",sr_amount," cash from ",sr_powername_from,". You now have ",sr_new_cash_to,".")
        );

/* */
End sproc;
END
$$

Delimiter ;

/*
Update sp_resource Set cash=1000, cash_transferred_in=0, cash_transferred_out=0 Where gameno=48;
select randgen from sp_resource where gameno=48 and userno=3227;
Update sp_game Set liquid_asset_percent=25 Where gameno=48;
Delete From sp_old_orders;
Delete from sp_messages;

-- Invalid game
Call sr_transfer_cash(99,"Canada","Europe",1000);

-- Invalid from power
Call sr_transfer_cash(48,"Concrete", "Europe", 1000);

-- Invalid to power
Call sr_transfer_cash(48,"Canada", "Arabia", 1000);

-- Invalid amount
Call sr_transfer_cash(48, "Canada", "Europe", -2000);

-- Excessive amount
Call sr_transfer_cash(48, "Canada", "Europe", 251);

-- Process transfer
Call sr_transfer_cash(48, "Canada", "Europe", 250);
Call sr_transfer_cash(48, "Europe", "Africa", 500);

-- Excessive 2nd transfer
Call sr_transfer_cash(48, "Canada", "Africa", 1);

Select * from sp_old_orders;
select * from sp_messages;
*/