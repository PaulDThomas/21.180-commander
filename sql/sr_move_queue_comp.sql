use asupcouk_asup;
Drop procedure if exists sr_move_queue_comp;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE  asupcouk_asup . sr_move_queue_comp  (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Create list of companies to purchase
-- $Id: sr_move_queue_comp.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_COMP";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE done INT DEFAULT 0;
DECLARE compxml TEXT DEFAULT '<COMPANIES><n>0</n></COMPANIES>';
DECLARE ncomps INT DEFAULT 0;
DECLARE sr_cardno INT DEFAULT 0;

DECLARE available CURSOR FOR
Select c.cardno
From sp_cards c
Join sp_res_cards rc On rc.cardno=c.cardno
Join sp_board b On c.gameno=b.gameno and b.terrno=rc.terrno and b.userno > -9
Where (c.userno=0 or c.userno is null)
 and c.gameno=sr_gameno
Order By rand()
Limit 10
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=7)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check for existing order
Select order_code, extractValue(order_code,'/COMPANIES/n') Into compxml, ncomps From sp_orders Where gameno=sr_gameno and ordername='SR_ACOMP';

-- Loop through available results
Set done=0;
OPEN available;
read_loop: LOOP
    Fetch From available Into sr_cardno;
    IF @sr_debug!='N' THEN Select sr_cardno, done, ncomps; END IF;
    IF done or ncomps >= 10 THEN LEAVE read_loop; END IF;

    -- Add Card if count < 10
    IF (extractValue(compxml,Concat("/COMPANIES/CardNo[text()='",sr_cardno,"']"))='') THEN
        Set ncomps = ncomps+1;
        Set compxml = updateXML(compxml,'/COMPANIES/n',Concat(sf_fxml('n',ncomps),sf_fxml('CardNo',sr_cardno)));
    END IF;
END LOOP;
CLOSE available;

-- Update order_code
Delete From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_phaseno and ordername='SR_ACOMP';
Insert Into sp_orders (gameno, turnno, phaseno, ordername, order_code)
Values (sr_gameno, sr_turnno, sr_phaseno, 'SR_ACOMP', compxml)
;

-- /* */
END sproc;
END
$$

Delimiter ;

/*
Delete from sp_orders Where gameno=48;
Delete from sp_old_orders;
Delete from sp_messages;
Update sp_game Set turnno=3, phaseno=6, process=null Where Gameno=48;
Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, 3, 6, 'ORDSTAT', 'Passed' From sp_resource Where gameno=48 and dead='N';
Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, 3, 7, 'ORDSTAT', 'Passed' From sp_resource Where gameno=48 and dead='N';
Update sp_orders Set order_code='First' Where gameno=48 and userno=3227 and phaseno=7;


Select * From sp_orders Where gameno=48;
-- Check game handled
Set @sr_debug='N';
call sr_move_queue(48);
Select * From sp_orders Where gameno=48;

-- Create list
-- Insert Into sp_orders (gameno, turnno, phaseno, ordername, order_code)
-- Values (48, 3, 7, 'SR_ACOMP', '<COMPANIES><Available><Cardno>1
-- ;
Set @sr_debug='N';

Update sp_orders Set order_code = "<COMPANIES><n>1</n><CardNo>28</CardNo></COMPANIES>"
Where gameno = 48 and ordername = 'SR_ACOMP';

-- select updateXML(order_code, "//Company[CardNo/text()='28']",sf_fxml('CardNo','*28*')) from sp_orders where gameno=48 and ordername='SR_ACOMP';

Call sr_move_queue_comp(48);
Select extractValue(order_code,'//n'), extractValue(order_code,'Count(//CardNo)') From sp_orders Where gameno=48 and ordername='SR_ACOMP';
*/