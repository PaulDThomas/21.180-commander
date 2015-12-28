use asupcouk_asup;
Drop procedure if exists sr_check_lstar_slots;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_check_lstar_slots` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Routine to check L-Star slots = L-Stars x (Strategic Tech + 3)
-- Declare variables
-- $Id: sr_check_lstar_slots.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_CHECK_LSTAR_SLOTS";
DECLARE sr_powername VARCHAR(15);
DECLARE sr_userno INT Default 0;
DECLARE sr_tech INT Default 0;
DECLARE sr_lstars INT Default 0;
DECLARE sr_cslots INT Default 0;
DECLARE i INT Default 0;
DECLARE j INT Default 0;
DECLARE done INT Default 0;

-- Get resource information
DECLARE powers CURSOR FOR
Select powername, userno, Case When dead='Y' then 0 Else lstars End, strategic_tech
From sp_resource 
Where gameno=sr_gameno
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game number
IF sr_gameno not in (Select gameno From sp_game Where phaseno != 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game</Reason><Value>",sr_gameno,"</Value></FAIL>"));
    LEAVE sproc;
    END IF;

-- Loop through all powers
OPEN powers;
read_loop: LOOP
    Fetch from powers Into sr_powername, sr_userno, sr_lstars, sr_tech;
    Select 0, 0 Into i,j;

	-- Leave the loop if no longer required
	IF done THEN
		LEAVE read_loop;
	END IF;

	IF @sr_debug='X' THEN
		Select "Deleting L-Star slots", sr_powername, sr_userno, sr_lstars, sr_tech, Count(*)
		From sp_lstars
		Where gameno=sr_gameno
		 and userno=sr_userno
		 and (lstarno >= sr_lstars or seqno >= sr_tech+3);
	END IF;

	-- Remove any extra lstarno slots
	Delete From sp_lstars Where gameno=sr_gameno and userno=sr_userno and (lstarno >= sr_lstars or seqno >= sr_tech+3);

	-- Get existing lstar information
	Select Count(*) Into sr_cslots From sp_lstars Where gameno=sr_gameno and userno=sr_userno;

	-- Add in extra lstar slots
	IF sr_cslots<>(sr_tech+3)*sr_lstars THEN
		--  Create L-Star tables with correct number of slots
		Create Temporary Table tmp_slots (lstarno INT, seqno INT);
		WHILE i < sr_lstars DO
			Set j=0;
			WHILE j < sr_tech+3 DO
				Insert Into tmp_slots Values (i,j);
				Set j=j+1;
			END WHILE;
			Set i=i+1;
		END WHILE;
		-- Remove already existing slots
		Delete From tmp_slots
		Where Exists (Select * From sp_lstars l Where tmp_slots.lstarno=l.lstarno and tmp_slots.seqno=l.seqno and gameno=sr_gameno and userno=sr_userno)
		;

		-- Add into the permanent L-Star table
		IF @sr_debug='X' THEN Select *, "Adding L-Star slots", sr_powername From tmp_slots; END IF;
		Insert Into sp_lstars (gameno, userno, lstarno, seqno, terrno) Select sr_gameno, sr_userno, lstarno, seqno, 0 From tmp_slots;

		-- Clean Up
		Drop Temporary Table tmp_slots;
	END IF;

END LOOP;

/* */
End sproc;
END
$$

Delimiter ;

/*
Drop Table If Exists tmp_slots;
Update sp_resource Set strategic_tech=4, lstars=1 Where gameno=48  and powername="Canada";
Delete From sp_old_orders;
Delete From sp_message_queue;
Delete From sp_lstars;

-- Check errors
-- Call sr_check_lstar_slots(99,"Canada");
-- Call sr_check_lstar_slots(48,"Bristol");

-- Check adding slots
Set @sr_debug='X';
Call sr_check_lstar_slots(48,"Canada");
Select gameno, userno, lstarno, Count(*) From sp_lstars Group By 1, 2, 3;

-- Check removing slots
Update sp_resource Set lstars=2,strategic_tech=1 Where gameno=48 and powername="Canada";
Call sr_check_lstar_slots(48,"Canada");
Select gameno, userno, lstarno, Count(*) From sp_lstars Group By 1, 2, 3;

Select * from sp_old_orders;
*/