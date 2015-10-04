use asupcouk_asup;
Drop procedure if exists sr_move_queue_2;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE  asupcouk_asup . sr_move_queue_2  (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Process income orders as generated by SR_MOVE_QUEUE_INCM
-- Should be called by the SR_MOVE_QUEUE macro
-- $Id: sr_move_queue_2.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_2";
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE last_phaseno INT DEFAULT 0;
DECLARE sr_fl INT DEFAULT 0;
DECLARE sr_phase2_type TEXT;
DECLARE sr_n INT DEFAULT 0;
DECLARE done INT DEFAULT 0;
DECLARE phasedesc TEXT;
DECLARE message_text TEXT DEFAULT '<BRIBES>';
DECLARE sr_cash INT DEFAULT 0;
DECLARE sr_powername TEXT;

DECLARE orders CURSOR FOR
Select userno, phaseno, cost
From tmp_phases
Order By phaseno, Cast(cost as signed) desc, rand()
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=2)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Create Table with all phase requests in from XML
Create Temporary Table tmp_phases As
Select userno, extractValue(order_code,'//P_A/Phase') as phaseno, extractValue(order_code,'//P_A/Cost') as cost From sp_orders Where gameno=sr_gameno and phaseno=1 and ordername='SR_ORDERXML'
UNION
Select userno, extractValue(order_code,'//P_B/Phase') as phaseno, extractValue(order_code,'//P_B/Cost') as cost From sp_orders Where gameno=sr_gameno and phaseno=1 and ordername='SR_ORDERXML'
UNION
Select userno, extractValue(order_code,'//P_C/Phase') as phaseno, extractValue(order_code,'//P_C/Cost') as cost From sp_orders Where gameno=sr_gameno and phaseno=1 and ordername='SR_ORDERXML'
;
Delete From tmp_phases Where phaseno='' or phaseno like 'P_';

-- Show table when debugging
IF @sr_debug != 'N' THEN
    Select "PHASE ALLOCATION TABLE:" As '', userno, phaseno, cost From tmp_phases Order By phaseno, Cast(cost as signed) desc;
END IF;

OPEN orders;
read_loop: LOOP
    FETCH FROM orders INTO sr_userno, sr_phaseno, sr_fl;
    -- Select sr_userno, sr_phaseno, sr_cash, sr_fl, done;
    IF done THEN LEAVE read_loop; END IF;

    -- Reset queue counter
    IF sr_phaseno != last_phaseno THEN Set sr_n = 1; END IF;

	-- Check cash is available
	Select cash Into sr_cash From sp_resource where userno=sr_userno and gameno=sr_gameno;
	IF Abs(sr_fl) > sr_cash THEN Set sr_fl = sr_cash*Sign(sr_fl); END IF;

	-- Add bribe to report if it has been set
	IF sr_fl != 0 THEN
		Set phasedesc = Case sr_phaseno
						 When 0 Then "Setup"
						 When 1 Then "Pay Salaries"
						 When 2 Then "Phase Selection"
						 When 3 Then "Sell"
						 When 4 Then "Move and Attack"
						 When 5 Then "Build and Research"
						 When 6 Then "Buy"
						 When 7 Then "Acquire Companies"
						 Else "Game over"
						End;
		Select powername into sr_powername From sp_resource Where gameno=sr_gameno and userno=sr_userno;
		Set message_text = Concat(message_text,sf_fxml('Bribe',Concat(sf_fxml('Powername',sr_powername),sf_fxml('Phasedesc',phasedesc),sf_fxml('Amount',Abs(sr_fl)))));
		-- Remove cash
		Update sp_resource Set cash=cash-Abs(sr_fl) Where gameno=sr_gameno and userno=sr_userno;
	END IF;

    -- Insert orders as requested
    Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, 'ORDSTAT'
           ,Case
             When sr_phaseno=5 or sr_n=1 Then 'First'
             Else Concat('In queue - ',sr_n)
            End
           );

    -- Set last phaseno
    Set last_phaseno = sr_phaseno;
    Set sr_n = sr_n+1;
END LOOP;

-- Insert missing orders into each phase
Set sr_n = 3;
WHILE sr_n <= 7 DO
    Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Select gameno, userno, sr_turnno, sr_n, 'ORDSTAT', 'Passed'
    From sp_resource r
    Where r.dead='N'
     and r.gameno=sr_gameno
     and r.userno not in (Select userno From sp_orders Where gameno=sr_gameno and phaseno=sr_n)
    ;
    Set sr_n = sr_n+1;
END WHILE;

Drop Temporary Table tmp_phases;

-- Insert Bribary report
IF message_text != '<BRIBES>' THEN
	Insert Into sp_message_queue (gameno, message) Values (sr_gameno, Concat(message_text,'</BRIBES>'));
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;