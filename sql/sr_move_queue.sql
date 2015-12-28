-- ALTER TABLE `asupcouk_asup`.`sp_game` ADD COLUMN `fortuna_flag` INT NULL DEFAULT 1 AFTER `boomer_tech_level`;
-- ALTER TABLE `asupcouk_asup`.`sp_newq_params` ADD COLUMN `fortuna_flag` INT NULL DEFAULT 1 AFTER `boomer_tech_level`;

use asupcouk_asup;
Drop procedure if exists sr_move_queue;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_move_queue` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- $Id: sr_move_queue.sql 270 2015-01-07 19:35:49Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE start_turnno INT DEFAULT 0;
DECLARE start_phaseno INT DEFAULT 0;
DECLARE sr_current_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_pass_user INT DEFAULT 0;
DECLARE sr_mia INT DEFAULT 0;
DECLARE sr_powername VARCHAR(15);
DECLARE sr_ordername VARCHAR(20);
DECLARE sr_ordercode TEXT;
DECLARE sr_posn TEXT;
DECLARE sr_tech INT DEFAULT 0;
DECLARE sr_terrname VARCHAR(25);
DECLARE done INT DEFAULT 0;
DECLARE sr_n INT DEFAULT 0;
DECLARE sr_deadline INT DEFAULT 0;
DECLARE sr_new_deadline INT DEFAULT 0;
DECLARE sr_full_message TEXT DEFAULT '';
DECLARE sr_full_email INT DEFAULT 0;
DECLARE sr_message TEXT;
DECLARE sr_to_email INT DEFAULT 0;
DECLARE last_userno INT DEFAULT 0;
DECLARE sr_boomerno INT DEFAULT 0;
DECLARE sr_boomer_terrno INT DEFAULT 0;
DECLARE sr_boomer_nukes INT DEFAULT 0;
DECLARE sr_boomer_neutron INT DEFAULT 0;
DECLARE sr_boomer_visible CHAR(1) DEFAULT 'N';
DECLARE sr_boomer_order_code TEXT;
DECLARE sr_fortuna_flag INT DEFAULT 1;

DECLARE orders CURSOR FOR
Select o.phaseno
       ,o.userno
       ,ordername
       ,order_code
       ,Case
         When ordername like 'MA%' Then Substring(ordername,4,3)
         When order_code = 'First' Then 500
         When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
         Else 9999
        End as posn
       ,mia
From sp_orders o
Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
Where o.gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno>=sr_current_phaseno
 and (ordername like 'MA%'
      or order_code like 'In queue%'
      or order_code = 'First'
      )
Order by phaseno
 ,Cast(posn As Signed)
;

DECLARE nuked_seas CURSOR FOR
Select terrname
From sp_board b
Left Join sp_places p On p.terrno=b.terrno
Left Join sp_resource r On r.userno=b.passuser
Where b.gameno=sr_gameno
 and p.terrno=b.terrno
 and b.userno in (-9,-10)
 and (Length(p.terrtype)=3 or r.dead='Y')
;

DECLARE boomers CURSOR FOR
Select r.powername, bm.userno, bm.boomerno, bm.terrno, bm.nukes, bm.neutron, bm.visible, o.order_code
From sp_boomers bm
Left Join sp_resource r
On bm.gameno=r.gameno and bm.userno=r.userno
Left Join sp_orders o
On bm.gameno=o.gameno and bm.userno=o.userno and o.ordername='SR_ORDERXML'
Where bm.gameno=sr_gameno
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno!=9)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno, turnno, phaseno, deadline_uts, fortuna_flag Into sr_turnno, sr_current_phaseno, start_turnno, start_phaseno, sr_deadline, sr_fortuna_flag From sp_game Where gameno=sr_gameno;

-- Check deadline if there is someone waiting
IF sr_deadline > unix_timestamp()
   and (Select Count(*) From sp_orders Where gameno=sr_gameno and ordername='ORDSTAT' and (order_code like 'Waiting%' or order_code='Orders processing'))>0 THEN
    Select Count(*) Into sr_userno From sp_orders Where gameno=sr_gameno and ordername='ORDSTAT' and (order_code like 'Waiting%' or order_code='Orders processing');
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL>",sf_fxml('Reason','Force pass too early')
                                                 ,sf_fxml('Game',sr_gameno)
                                                 ,sf_fxml('WaitingUsers',sr_userno)
                                                 ,sf_fxml('Deadline_UTS',sr_deadline)
                                                 ,sf_fxml('Now',unix_timestamp())
                                        ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Get current userno for MA
Select userno
Into last_userno
From sp_orders
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=4
 and (ordername='MA_000' or order_code='Orders processed')
Order By ordername
Limit 1
;

-- Lets have a look at when we're going to process...
IF @sr_debug!='N' THEN
    Select 'Before intro rules', sr_current_phaseno, sr_pass_user
           ,o.phaseno
           ,o.userno
           ,ordername
           ,order_code
           ,Case
             When ordername like 'MA%' Then Substring(ordername,4,3)
             When order_code = 'First' Then 500
             When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
             Else 9999
            End as posn
           ,mia
           ,sr_pass_user
		   ,last_userno
    From sp_orders o
    Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
    Where o.gameno=sr_gameno
    Order by phaseno, Cast(posn as signed), userno
    ;
END IF;

-- Copy existing orders into old_orders table
Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, turnno, phaseno, ordername, order_code
From sp_orders
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and ordername not in ('ORDSTAT','SR_ACOMP','REDEPLOY','att_terr','def_terr','def_power','Action')
 and binary Substring(ordername,1,2) != 'MA'
;

-- Get user being force passed for MA orders only
Create Temporary Table tmp_forced As
Select userno
From sp_orders
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and (ordername='ORDSTAT' or ordername like binary 'MA%')
 and (order_code like 'Waiting%' or order_code='Orders processing')
-- Remove an original userno that is passing on an MA (must have Orders processed)
 and userno not in (Select userno From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=sr_current_phaseno and ordername='ORDSTAT' and order_code='Orders processed')
;
-- Get forced userno for attack phase when MA orders could exist
Select userno Into sr_pass_user From tmp_forced Where sr_current_phaseno=4;
IF @sr_debug != 'N' THEN Select "MIA users", userno, sr_pass_user From tmp_forced; END IF;

-- Add message for force pass
Insert Into sp_messages (gameno, userno, message)
Select sr_gameno, userno, Concat('You have missed the deadline for turn ',sr_turnno,', phase ',sr_current_phaseno,'.')
From tmp_forced
;

-- Update MIA for force pass
Update sp_resource Set mia=mia+1
Where userno in (Select userno
                 From tmp_forced
                 )
 and gameno=sr_gameno
 ;

-- Move existing queue orders
Update sp_orders
Set order_code = 'Passed'
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and userno in (Select userno From tmp_forced)
 and ordername='ORDSTAT'
;

-- Delete extra MA orders if if being forced
IF @sr_debug='X' THEN
    Select *
    From sp_orders
    Where ordername like 'MA\_0__\_%'
     and gameno=sr_gameno
     and turnno=sr_turnno
     and phaseno=sr_current_phaseno
     and userno in (Select userno From tmp_forced)
    ;
END IF;
Delete From sp_orders
Where ordername like 'MA\_0__\_%'
 and gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and userno in (Select userno From tmp_forced)
;
Drop Table tmp_forced;

-- Process phase 1 before deleting orders
IF sr_current_phaseno=1 THEN
	Call sr_company_trading(sr_gameno);
    Call sr_move_queue_1(sr_gameno);
	-- Move boomers
    Set done=0;
    OPEN boomers;
    read_loop: LOOP
        FETCH boomers Into sr_powername, sr_userno, sr_boomerno, sr_boomer_terrno, sr_boomer_nukes, sr_boomer_neutron, sr_boomer_visible, sr_boomer_order_code;
        IF done THEN LEAVE read_loop; END IF;
	    Call sr_boomer_move(sr_gameno, sr_powername, sr_boomerno
                           ,ExtractValue(sr_boomer_order_code,Concat('/PAYSALARIES/Boomer/Terrname[../Number/text()="',sr_boomerno,'"]'))
                           ,ExtractValue(sr_boomer_order_code,Concat('/PAYSALARIES/Boomer/Visible[../Number/text()="',sr_boomerno,'"]'))
                           ,ExtractValue(sr_boomer_order_code,Concat('/PAYSALARIES/Boomer/Nukes[../Number/text()="',sr_boomerno,'"]'))
                           ,ExtractValue(sr_boomer_order_code,Concat('/PAYSALARIES/Boomer/Neutron[../Number/text()="',sr_boomerno,'"]'))
                           );
    END LOOP;
    CLOSE boomers;
	
    Set sr_current_phaseno=2;
    Update sp_game Set phaseno=2 Where gameno=sr_gameno;
    Call sr_move_queue_2(sr_gameno);
    Delete From sp_orders Where gameno=sr_gameno and phaseno<=2;
-- Process phase 0 before deleting orders
ELSEIF sr_current_phaseno=0 THEN
    Set sr_current_phaseno=7;  -- To allow move to next phase
	Call sr_company_trading(sr_gameno);
    Call sr_move_queue_0(sr_gameno);
ELSEIF sr_current_phaseno=5 THEN
	Call sr_company_trading(sr_gameno);
    Call sr_move_queue_5(sr_gameno);
END IF;

-- Lets have a look at when we're going to process...
IF @sr_debug!='N' THEN
    Select 'After phase processing', sr_current_phaseno, sr_pass_user
           ,o.phaseno
           ,o.userno
           ,ordername
           ,order_code
           ,Case
             When ordername like 'MA%' Then Substring(ordername,4,3)
             When order_code = 'First' Then 500
             When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
             Else 9999
            End as posn
           ,mia
           ,sr_pass_user
    From sp_orders o
    Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
    Where o.gameno=sr_gameno
    Order by phaseno, Cast(posn as signed), userno
    ;
END IF;

-- Delete used orders
Delete From sp_orders
Where gameno=sr_gameno
 and turnno<=sr_turnno
 and phaseno<=sr_current_phaseno
 and ordername not in ('SR_ACOMP','ORDSTAT','REDEPLOY')
 and (ordername not like binary 'MA%' or ordername like 'MA_000%')
;

-- Move processed queue orders to end of the queue
-- Get number of MA orders for everyone, Do NOT move the main queue if there is an MA sub-queue
Select Count(*) Into sr_n
From sp_orders o
Left Join sp_resource r On o.userno=r.userno and o.gameno=r.gameno
Where o.gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and ordername like 'MA%'
 and mia < 3
;
-- Then move to the end of the queue,
IF @sr_debug != 'N' THEN
    Select *, "Should be in queue 99" from sp_orders
    Where gameno=sr_gameno
    and order_code = 'Orders processed'
    and (   (phaseno in (3, 6, 7))
        or (phaseno=4 and sr_n = 0)
        )
    ;
END IF;
Update sp_orders
Set order_code = 'In queue - 99'
Where gameno=sr_gameno
 and turnno=sr_turnno
 and phaseno=sr_current_phaseno
 and order_code = 'Orders processed'
 and (   (phaseno in (3, 6, 7))
      or (phaseno=4 and sr_n = 0)
      )
;

-- Lets have a look at when we're going to process...
IF @sr_debug='X' THEN
    Select 'Before alive check', sr_current_phaseno, sr_pass_user
           ,o.phaseno
           ,o.userno
           ,ordername
           ,order_code
           ,Case
             When ordername like 'MA%' Then Substring(ordername,4,3)
             When order_code = 'First' Then 500
             When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
             Else 9999
            End as posn
           ,mia
           ,sr_pass_user
    From sp_orders o
    Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
    Where o.gameno=sr_gameno
    Order by phaseno, Cast(posn as signed), userno
    ;
END IF;

-- CHECK EVERYONE IS STILL ALIVE!!!!
Call sr_check_alive(sr_gameno);

-- Lets have a look at when we're going to process...
IF @sr_debug!='N' THEN
    Select 'After intro rules', sr_current_phaseno, sr_pass_user
           ,o.phaseno
           ,o.userno
           ,ordername
           ,order_code
           ,Case
             When ordername like 'MA%' Then Substring(ordername,4,3)
             When order_code = 'First' Then 500
             When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
             Else 9999
            End as posn
           ,mia
           ,sr_pass_user
    From sp_orders o
    Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
    Where o.gameno=sr_gameno
    Order by phaseno, posn, userno
    ;
END IF;

-- Move through current orders, until next player found or end of turn reached
Set done=0;
Set sr_posn = 0;
Set sr_userno = 0;
Set sr_n = 0;  -- Use sr_n as a flag for processing completion, 0=Not complete, 1=Waiting, 2=MA, 99=Completed
OPEN orders;
read_loop: LOOP
    FETCH FROM orders Into sr_phaseno, sr_userno, sr_ordername, sr_ordercode, sr_posn, sr_mia;

    -- Lets have a look at when we've going to process...
    IF @sr_debug='X' THEN
        select 'Start of phase loop', sr_n, sr_current_phaseno, sr_phaseno, sr_userno, sr_ordername, sr_ordercode, sr_posn, sr_mia, done;
    END IF;

    -- Leave the loop if no longer required
    IF done
     or (sr_phaseno > sr_current_phaseno and sr_n > 0) THEN
		Set sr_n=99;
        LEAVE read_loop;
    END IF;

    -- Fortuna if the phases have moved...
    WHILE sr_current_phaseno < sr_phaseno DO
        -- Clean up and move to next phase
        Set sr_current_phaseno=sr_current_phaseno+1;
        Delete from sp_orders Where gameno=sr_gameno and phaseno<sr_current_phaseno;
        Update sp_game Set phaseno=sr_current_phaseno Where gameno=sr_gameno;
        -- Fortuna
        IF sr_fortuna_flag > 0 THEN 
            Call sr_fortuna(sr_gameno);
        END IF;
    END WHILE;

    -- If phase 5 set to waiting (or pass for MIA)
    IF sr_current_phaseno = 5 THEN
        Update sp_orders o
        Join sp_resource r On o.gameno=r.gameno and o.userno=r.userno
        Set order_code = Case
                          When mia >= 3 or order_code='Passed' Then 'Passed'
                          Else 'Waiting for orders'
                         End
        Where o.gameno = sr_gameno
         and turnno = sr_turnno
         and phaseno = 5
         and ordername = 'ORDSTAT'
        ;
        IF 0<(Select Count(*) From sp_orders Where gameno=sr_gameno and order_code like 'Waiting%') THEN
            LEAVE read_loop;
        END IF;

    -- Deal with missing players
    ELSEIF sr_n=0 and (sr_mia >= 3 or sr_userno=sr_pass_user) and sr_phaseno!=5 THEN
        -- Delete MA orders
        Delete From sp_orders
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
         and ordername like 'MA%';
        -- Set other orders to Pass
        Update sp_orders
        Set order_code = 'Passed'
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
         and ordername not like 'MA%'
        ;
        Set sr_userno=0;

    -- Handle next order
    -- Redeploy
    ELSEIF sr_n=0 and sr_posn > 0 and (Substring(sr_ordername,8)='REAT' or Substring(sr_ordername,8)='REDE') THEN
        -- Update main order
        Update sp_orders
        Set ordername='MA_000', order_code='Waiting for redeploy'
        Where gameno=sr_gameno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=2;
        LEAVE read_loop;

    -- Retaliate
    ELSEIF sr_n=0 and sr_posn > 0 and Substring(sr_ordername,8)='RET' THEN
        -- Add in row for retaliation against powername
        Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
        Values (sr_gameno, sr_turnno, sr_phaseno, sr_userno, 'MA_000_user', sr_ordercode)
        ;
        -- Get powername to attack
        Select powername Into sr_powername From sp_resource Where gameno=sr_gameno and userno=sr_ordercode;
        -- Update main order
        Update sp_orders
        Set ordername='MA_000', order_code=Concat('Waiting for retaliation against ',sr_powername)
        Where gameno=sr_gameno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=2;
        LEAVE read_loop;

    -- Extra attack to process
    ELSEIF sr_n=0 and sr_posn > 0 and Substring(sr_ordername,8)='ATT' THEN
        -- Update main order
        Update sp_orders
        Set ordername='MA_000'
        Where gameno=sr_gameno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_n=2;
        LEAVE read_loop;

    -- If user has been found set to waiting
    ELSEIF sr_n=0 and sr_userno > 0 THEN
        Update sp_orders
        Set order_code='Waiting for orders'
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        -- Add in extra attacks
        IF sr_phaseno = 4 THEN
            Select Least(land_tech, water_tech) Into sr_tech From sp_resource Where gameno=sr_gameno and userno=sr_userno;
            Set sr_n = 1;
            WHILE sr_n < sr_tech DO
                Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
                Values (sr_gameno, sr_turnno, sr_phaseno, sr_userno, Concat('MA_',LPAD(sr_n,3,'0'),'_ATT'), Concat('Extra Move/Attack ',sr_n));
                Set sr_n=sr_n+1;
            END WHILE;
        END IF;
        Set sr_n = 1;

    -- Assign next queue number, no changes to MIA people here!
    ELSEIF sr_n > 0 and sr_ordername = 'ORDSTAT' and sr_ordercode like 'In queue%' and sr_phaseno = sr_current_phaseno THEN
        Update sp_orders
        Set order_code=Concat('In queue - ',sr_n)
        Where gameno=sr_gameno
         and turnno=sr_turnno
         and phaseno=sr_phaseno
         and userno=sr_userno
         and ordername=sr_ordername
        ;
        Set sr_ordercode=Concat('In queue - ',sr_n);
        Set sr_n=sr_n+1;
    END IF;

    -- Lets have a look at when we've going to process...
    IF @sr_debug='X' THEN
        Select 'End of phase loop'
               ,sr_n
               ,o.phaseno
               ,o.userno
               ,ordername
               ,order_code
               ,Case
                 When ordername like 'MA%' Then Substring(ordername,4,3)
                 When order_code = 'First' Then 500
                 When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
                 Else 9999
                End as posn
               ,mia
               ,sr_userno
        From sp_orders o
        Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
        Where o.gameno=sr_gameno
        Order by o.phaseno, posn, turnno, phaseno, userno
        ;

    END IF;

END LOOP;

IF @sr_debug='X' THEN
    select "After loop", sr_current_phaseno, sr_userno, sr_n;
END IF;

-- Delete REDEPLOY order is none are pending
IF (Select Count(*) From sp_orders Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4 and ordername like 'MA_____RE%') = 0 THEN
    Delete From sp_orders
    Where gameno=sr_gameno
     and turnno<=sr_turnno
     and phaseno=4
     and ordername='REDEPLOY'
    ;
END IF;

-- CHECK EVERYONE IS STILL ALIVE AGAIN!!!!
Call sr_check_alive(sr_gameno);


-- Double check that user has not been set to Pass in loop (can happen when all phase 5 are MIA)
IF (Select Count(*) From sp_orders Where gameno=sr_gameno and ordername='ORDSTAT' and order_code in ('Waiting for orders','Orders processed')) = 0 THEN
    Set sr_userno=0;
-- Add build orders if its phase 5
ELSEIF sr_current_phaseno=5 THEN
    Call sr_move_queue_build(sr_gameno);
-- Add available companies if its phase 7
ELSEIF sr_current_phaseno=7 and sr_turnno>0 THEN
    Call sr_move_queue_comp(sr_gameno);
END IF;

-- Move to the next turn if no one has been processed
IF sr_userno <= 0 and (Select Count(*) From sp_resource Where gameno=sr_gameno and dead='N') > 1 THEN
    -- Fortuna if the phases have not moved enough...
    WHILE sr_current_phaseno < 7 DO
        -- Clean up and move to next phase
        Set sr_current_phaseno=sr_current_phaseno+1;
        Update sp_game Set phaseno=sr_current_phaseno Where gameno=sr_gameno;
        -- Fortuna
        IF sr_fortuna_flag > 0 THEN 
            Call sr_fortuna(sr_gameno);
        END IF;
    END WHILE;

    -- Clean up and move to next turn
    Delete From sp_orders Where gameno=sr_gameno and turnno=sr_turnno;
    Set sr_turnno=sr_turnno+1;
    Set sr_phaseno=1;
    Set sr_current_phaseno=1;
    Update sp_game Set turnno=sr_turnno, phaseno=sr_phaseno Where gameno=sr_gameno;

    -- Clear any nuked or neutroned seas or dead peoples neutrons
    Set done=0;
    OPEN nuked_seas;
    read_loop: LOOP
        FETCH nuked_seas Into sr_terrname;
        IF done THEN LEAVE read_loop; END IF;
        Call sr_take_territory(sr_gameno, sr_terrname, 'Neutral', 0, 0);
    END LOOP;
    CLOSE nuked_seas;

    -- Add interest on loans
    Update sp_resource
    Set interest=interest+(Select price From sp_loan l Where l.loan_level=sp_resource.loan)
    Where gameno=sr_gameno
    ;

    -- Add income orders for phase 1
    Call sr_move_queue_incm(sr_gameno);

END IF;


-- Move messages from the message queue
call sr_message_queue(sr_gameno);


-- Update deadline
IF @sr_debug = 'X' THEN 
	Select "Update timestamp", sr_n, last_userno, sr_userno;
END IF;
IF sr_n != 2 or sr_userno != last_userno THEN
	Update sp_game Set deadline_uts=Greatest(deadline_uts, Unix_Timestamp()+advance_uts) Where gameno=sr_gameno;
ELSEIF @sr_debug = 'X' THEN 
	Select "No time increment";
END IF;
Select deadline_uts Into sr_new_deadline From sp_game Where gameno=sr_gameno;

-- Delete old waiting messages
Delete From sp_messages Where gameno=sr_gameno and message like '<WAIT>%</WAIT>';
-- Add waiting message
Insert Into sp_messages (gameno, userno, message, to_email)
Select o.gameno, o.userno, sf_fxml("WAIT",Concat("Waiting for your orders"
                                                ,sf_fxml("Game",o.gameno)
                                                ,sf_fxml("Turn",g.turnno)
                                                ,sf_fxml("Phase",g.phaseno)
                                                ,sf_fxml("UTS",deadline_uts)
                                                ,sf_fxml("dt_format",u.dt_format)
                                                ,sf_fxml("offset",u.timezone)
                                                )
                                   ), -9
From sp_orders o
Left Join sp_game g on o.gameno=g.gameno
Left Join sp_resource r on o.gameno=r.gameno and o.userno=r.userno
Left Join sp_users u on r.userno=u.userno
Where o.gameno=sr_gameno
 and order_code like 'Waiting%'
 and mia < 3
;

-- Update randgen
Update sp_resource Set randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10) Where gameno=sr_gameno;

-- Add Old Order
Insert Into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
Values (sr_gameno, sr_turnno, sr_current_phaseno, proc_name
       ,sf_fxml("SUCCESS",Concat(sf_fxml("OldTurn",start_turnno)
                                ,sf_fxml("OldPhase",start_phaseno)
                                ,sf_fxml("NewTurn",sr_turnno)
                                ,sf_fxml("NewPhase",sr_current_phaseno)
                                ,sf_fxml("OldDeadline",from_unixtime(sr_deadline))
                                ,sf_fxml("NewDeadline",from_unixtime(sr_new_deadline))
                                )
                )
       );

-- Lets have a look at when we've processed...
IF @sr_debug!='N' THEN
    Select 'Final'
           ,o.userno
           ,o.turnno
           ,o.phaseno
           ,ordername
           ,order_code
           ,Case
             When ordername like 'MA%' Then Substring(ordername,4,3)
             When order_code = 'First' Then 500
             When order_code like 'In queue%' Then Substring(order_code,12,3)+1000
             Else 9999
            End as posn
           ,mia
           ,sr_userno
    From sp_orders o
    Left Join sp_resource r On r.gameno=o.gameno and r.userno=o.userno
    Where o.gameno=sr_gameno
    Order by turnno, phaseno, Cast(posn as signed), o.userno
    ;
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;
