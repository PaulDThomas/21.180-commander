use asupcouk_asup;
Drop procedure if exists sr_4_pass;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_4_pass` (sr_gameno INT
                                      ,sr_powername VARCHAR(15)
                                      )
BEGIN
sproc:BEGIN

-- $Id: sr_4_pass.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_4_PASS";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_ma INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_current_powername VARCHAR(15);
DECLARE sr_waiting_powername VARCHAR(15);
DECLARE sr_redeploy INT Default 0;
DECLARE sr_retaliation INT Default 0;
DECLARE sr_extra INT Default 0;

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno < 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
Select turnno, phaseno, current_powername, waiting_powername, waiting_userno, redeploy, retaliation, extra
Into sr_turnno, sr_phaseno, sr_current_powername, sr_waiting_powername, sr_userno, sr_redeploy, sr_retaliation, sr_extra
From sv_next_powers Where gameno=sr_gameno;

-- Check powername
IF sr_powername != sr_waiting_powername THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Power</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,sf_fxml("Powername",sr_powername)
                                         ,sf_fxml("WaitingPowername",sr_waiting_powername)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;

-- Move on if waiting = current and first order
IF sr_powername = sr_current_powername THEN
    -- Delete any remaining ATT orders
    Delete From sp_orders
    Where gameno=sr_gameno
     and userno=sr_userno
     and turnno=sr_turnno
     and phaseno=sr_phaseno
     and ordername like 'MA\_0__\_ATT'
    ;
    -- Set orders processed if something has already happened
    IF Greatest(sr_redeploy, sr_retaliation, sr_extra) >0 THEN
        Update sp_orders
        Set order_code='Orders processed'
        Where gameno=sr_gameno
         and userno=sr_userno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and ordername='ORDSTAT'
        ;
    ELSE
        Update sp_orders
        Set order_code='Passed'
        Where gameno=sr_gameno
         and userno=sr_userno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and ordername='ORDSTAT'
        ;
    END IF;

-- Pass from non-current power
ELSE
    Update sp_orders
    Set order_code='Passed'
    Where gameno=sr_gameno
     and userno=sr_userno
     and turnno=sr_turnno
     and phaseno=sr_phaseno
     and order_code like 'Waiting%'
    ;
END IF;

-- Always move queue
Call sr_move_queue(sr_gameno);


END sproc;
END
$$

Delimiter ;
