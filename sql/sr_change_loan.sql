use asupcouk_asup;
Drop procedure if exists sr_change_loan;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_change_loan` (sr_gameno INT, sr_powername VARCHAR(15), sr_amount INT)
BEGIN
sproc:BEGIN

-- Declare variables
-- $Id: sr_change_loan.sql 323 2015-12-19 21:25:27Z paul $
DECLARE proc_name CHAR(15) Default "SR_CHANGE_LOAN";
DECLARE sr_userno INT Default 0;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_current_amount INT Default 0;
DECLARE sr_max_amount INT Default 0;
DECLARE sr_companies INT Default 0;
DECLARE sr_new_cash INT Default 0;
DECLARE sr_new_loan INT Default 0;

-- Check game number
IF sr_gameno not in (Select gameno From sp_game Where phaseno != 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game</Reason><Value>",sr_gameno,"</Value></FAIL>"));
    LEAVE sproc;
    END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check powername
IF Upper(sr_powername) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid Power</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Get game information
Select userno, loan Into sr_userno, sr_current_amount From sp_resource Where gameno=sr_gameno and powername=sr_powername;
Select Count(*) Into sr_companies From sp_cards Where gameno=sr_gameno and userno=sr_userno;
Set sr_max_amount = 1000*Least(12,Floor(sr_companies/2));

-- Check something is happening
IF sr_amount=0 THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>No loan request</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("MaxAmount",sr_max_amount)
                   ,sf_fxml("CurrentAmount",sr_current_amount)
                   ,sf_fxml("RequestedAmount",sr_amount)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Check new amount is available
IF sr_current_amount+sr_amount not between 0 and sr_max_amount THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<FAIL><Reason>Invalid loan request</Reason>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Userno",sr_powername)
                   ,sf_fxml("MaxAmount",sr_max_amount)
                   ,sf_fxml("CurrentAmount",sr_current_amount)
                   ,sf_fxml("RequestedAmount",sr_amount)
                   ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Process loan change
Update sp_resource
Set loan=loan+sr_amount, cash=cash+sr_amount, randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10)
Where gameno=sr_gameno
 and powername=sr_powername
;

-- Get new details
Select cash, loan Into sr_new_cash, sr_new_loan From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Set success message
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat("<SUCCESS><Action>Change Loan</Action>"
                   ,sf_fxml("Gameno",sr_gameno)
                   ,sf_fxml("Powername",sr_powername)
                   ,sf_fxml("Userno",sr_powername)
                   ,sf_fxml("MaxAmount",sr_max_amount)
                   ,sf_fxml("CurrentAmount",sr_current_amount)
                   ,sf_fxml("RequestedAmount",sr_amount)
                   ,"</SUCCESS>")
        );

-- Set message
IF sr_amount < 0 THEN
    Insert Into sp_message_queue (gameno, userno, message)
     Values (sr_gameno, sr_userno
            ,Concat("You have repaid ",-sr_amount," of your loan.  It now stands at ",sr_new_loan,".")
            );
ELSE
    Insert Into sp_messages (gameno, userno, message)
     Values (sr_gameno, sr_userno
            ,Case
              When sr_current_amount=0 Then Concat("You have taken a loan out for ",sr_amount,". You now have ",sr_new_cash," cash.")
              Else Concat("You have increased your loan by ",sr_amount,". Your total loan is now ",sr_new_loan," and you have ",sr_new_cash," cash.")
             End
            );
END IF;
/* */
End sproc;
END
$$

Delimiter ;
/*
Update sp_resource Set loan=0 Where gameno=64;
Delete From sp_old_orders;
Delete From sp_message_queue;
Delete from sp_messages;

Call sr_change_loan(99,"Canada",1000);
Call sr_change_loan(64,"Arabia",2000);
Call sr_change_loan(64,"Canada",0);

Call sr_change_loan(64,"Canada",3000);
Call sr_change_loan(64,"Canada",3000);
Call sr_change_loan(64,"Canada",13000);

Call sr_change_loan(64,"Canada",-4000);
Call sr_change_loan(64,"Canada",-4000);
Call sr_change_loan(64,"Canada",-2000);

Select * from sp_old_orders;
Select * from sp_message_queue;
select * from sp_messages;
*/