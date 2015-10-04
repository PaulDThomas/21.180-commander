use asupcouk_asup;
Drop procedure if exists sr_message_queue;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_message_queue` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- $Id: sr_message_queue.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MESSAGE_QUEUE";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_message TEXT;
DECLARE sr_to_email INT DEFAULT 0;
DECLARE last_userno INT DEFAULT -11;
DECLARE done INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_full_message TEXT DEFAULT '';
DECLARE sr_full_email INT DEFAULT 0;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

IF @sr_debug='X' THEN Select * From sp_message_queue; END IF;

-- Move messages from the message queue
Insert Into sp_messages (gameno, userno, to_email, message)
Select gameno, userno, to_email, group_concat(message order by messageno separator '\n')
From sp_message_queue
Where gameno=sr_gameno
 and userno!=-7
 and message not like '<%'
Group By gameno, userno, to_email
;

-- Now copy reports
Insert Into sp_messages (gameno, userno, message)
Select gameno, userno, message
From sp_message_queue m
Where gameno=sr_gameno
 and userno!=-7
 and message like '<%'
;

-- Copy messages that need to split into the message queue.  These should never me appended to another
Insert Into sp_messages (gameno, userno, message)
Select m.gameno, r.userno, message
From sp_message_queue m
Inner Join sp_resource r
On r.gameno=m.gameno and r.powername=ExtractValue(message,'//AttPowername')
Where m.gameno=sr_gameno
 and m.userno=-7
;
Insert Into sp_messages (gameno, userno, message)
Select m.gameno, r.userno, message
From sp_message_queue m
Inner Join sp_resource r
On r.gameno=m.gameno and r.powername=ExtractValue(message,'//DefPowername')
Where m.gameno=sr_gameno
 and m.userno=-7
;

Delete From sp_message_queue Where gameno=sr_gameno;

-- /* */
END sproc;
END
$$

Delimiter ;