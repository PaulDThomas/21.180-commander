use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_move_queue_numbers;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_move_queue_numbers` (sr_gameno INT, OUT sr_n INT)
BEGIN
sproc:BEGIN

-- $Id: sr_move_queue_numbers.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_NUMBERS";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_ordername TEXT;
DECLARE sr_posn TEXT;
DECLARE sr_tech INT DEFAULT 0;
DECLARE sr_mia INT DEFAULT 0;
DECLARE done INT DEFAULT 0;
DECLARE sr_i INT DEFAULT 1;

DECLARE orders CURSOR FOR
Select userno, ordername, Substring(order_code,11) as posn
From sp_orders
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_phaseno
 and ordername='ORDSTAT'
 and (order_code like 'In queue%'
      or order_code='Orders processed'
      or order_code='First'
      or order_code='Waiting for orders'
      )
Order by posn
;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno!=9)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

Set sr_n=0;
OPEN orders;
read_loop: LOOP
    FETCH orders INTO sr_userno, sr_ordername, sr_posn;
    IF done THEN LEAVE read_loop; END IF;
    -- Get MIA status of first person in the queue
    Select mia Into sr_mia From sp_resource Where gameno=sr_gameno and userno=sr_userno;
    -- Set to passed if power is MIA
    IF sr_mia >= 3 THEN
        Update sp_orders
        Set order_code = 'Passed'
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
    -- Set everyone to Waiting if phase number is 1 or 5
    ELSEIF sr_phaseno in (1,5) THEN
        Update sp_orders
        Set order_code='Waiting for orders'
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=sr_n+1;
    -- Set to next if queue for the first person
    ELSEIF sr_n=0 THEN
        Update sp_orders
        Set order_code='Waiting for orders'
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=sr_n+1;

        -- Check for extra attacks if it is phase 4
        IF sr_phaseno=4 THEN
            Select Least(land_tech, water_tech)
            Into sr_tech
            From sp_resource r
            Where gameno=sr_gameno
             and userno=sr_userno
            ;
            Set sr_i = 1;
            WHILE sr_i < sr_tech DO
                Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
                Values (sr_gameno, sr_turnno, sr_phaseno, sr_userno, Concat('MA_',LPAD(sr_i,3,'0'),'_ATT'), Concat('Extra Move/Attack ',sr_i));
                Set sr_i=sr_i+1;
            END WHILE;
        END IF;

    -- Set to in queue for subsequent people
    ELSE
        Update sp_orders
        Set order_code=Concat('In queue - ',sr_n)
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=sr_n+1;
    END IF;
END LOOP;
CLOSE orders;

-- /* */
END sproc;
END
$$

Delimiter ;
/*
Delete From sp_old_orders;
Update sp_resource Set mia=0 Where gameno=48;
Update sp_resource Set mia=9 Where gameno=48 and userno=3238;

Delete from sp_orders;
Update sp_game Set phaseno=7 Where gameno=48;
Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
 Select g.gameno, turnno, phaseno, userno, 'ORDSTAT', 'Passed'
 From sp_resource r, sp_game g
 Where g.gameno=48 and r.gameno=g.gameno
;

Update sp_orders Set order_code='First' Where ordername='ORDSTAT' and gameno=48 and userno=3238;
Update sp_orders Set order_code='In queue - 1' Where ordername='ORDSTAT' and gameno=48 and userno=3227;
Update sp_orders Set order_code='In queue - 2' Where ordername='ORDSTAT' and gameno=48 and userno=3448;
-- Update sp_orders Set order_code='Passed' Where ordername='ORDSTAT' and gameno=48 and phaseno=4;

Select * From sp_orders Where gameno=48 and order_code != 'Passed';
Call sr_move_queue_numbers(48,@sr_n);
Select *, @sr_n From sp_orders Where gameno=48 and order_code != 'Passed';
*/