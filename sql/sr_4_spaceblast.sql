use asupcouk_asup;
Drop procedure if exists sr_4_spaceblast;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_4_spaceblast` (sr_gameno INT
                                            ,sr_powername TEXT
                                            ,sr_nukes INT
                                            )
BEGIN
sproc:BEGIN

-- $Id: sr_4_spaceblast.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_4_SPACEBLAST";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_avail_nukes INT Default 0;
DECLARE i INT Default 0;
DECLARE r DOUBLE Default 0;
DECLARE sr_def_powername TEXT;
DECLARE sr_def_userno INT;
DECLARE sr_def_lstars INT Default 0;
DECLARE sr_def_ksats INT Default 0;
DECLARE sr_slots INT Default 0;
DECLARE done INT DEFAULT 0;
DECLARE sr_report TEXT Default '';
DECLARE sr_retaliation INT Default 0;

-- Declare cursors for results
DECLARE blanket CURSOR FOR Select Distinct userno, powername, blanket, lstars, ksats From tmp_targets Where userno!=sr_userno;

-- Cursor Handler
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno < 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    Leave sproc;
End If;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Check powername
If sr_powername not in (Select powername From sp_resource r Where gameno=sr_gameno and dead='N') Then
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Invalid Power</Reason>"
				  ,sf_fxml("Gameno",sr_gameno)
				  ,sf_fxml("Powername",sr_powername)
				  ,"</FAIL>")
		   );
    LEAVE sproc;
END IF;
Select userno, nukes Into sr_userno, sr_avail_nukes From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Check positive nukes
IF sr_nukes < 1 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>No warheads</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("AvailableNukes",sr_avail_nukes)
                  ,sf_fxml("Nukes",sr_nukes)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check enough nukes are available
IF sr_nukes > sr_avail_nukes THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Not enough warheads</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("AvailableNukes",sr_avail_nukes)
                  ,sf_fxml("Nukes",sr_nukes)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check right power is processing
IF sr_userno = (Select userno From sp_orders
                Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                      and ordername = 'MA_000'
                      and order_code like 'Waiting for retaliation%') THEN
    -- Retaliation Space Blasts not allowed
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Retaliation Space Blasts not allowed</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,"</FAIL>"));
    LEAVE sproc;
ELSEIF sr_userno = (Select userno From sp_orders
                    Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                          and ordername='ORDSTAT'
                          and order_code in ('Orders processed','Waiting for orders')
                     )
        and 0 = (Select Count(*) From sp_orders
                 Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                       and ordername='MA_000'
                       and order_code like 'Waiting for retaliation%') THEN
    -- Normal attack
    Set sr_retaliation=0;
ELSE
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
    Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Invalid power to process</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Check L-Star slots are correct for the game
Call sr_check_lstar_slots(sr_gameno);

-- Create empty target table
Drop Temporary Table If Exists tmp_targets;
Create Temporary Table tmp_targets (powername TEXT
                                   ,userno INT
                                   ,lstars INT
                                   ,ksats INT
                                   ,killed INT Default 0
								   ,blanket INT Default 0
                                   ,blanket_n INT Default 0
                                   ,blanket_r DOUBLE
                                   ,random_order DOUBLE
                                   );
Insert Into tmp_targets (powername, userno, lstars, ksats, blanket)
 Select r.powername
		,r.userno
		,r.lstars
		,r.ksats
		,Sum(Case When terrno=0 Then 1 Else 0 End) As blanket
 From   sp_resource r
 Left Join sp_lstars l On r.userno=l.userno
 Where  r.gameno=sr_gameno
  and   Greatest(r.lstars,r.ksats) > 0 
 Group By r.powername
		,r.userno
		,r.lstars
		,r.ksats
 ;

-- Look at target table
IF @sr_debug!='N' THEN Select *, "Initial TMP targets" from tmp_targets; END IF;

-- Remove warheads from resource card
Update sp_resource
Set nukes = nukes - sr_nukes
Where gameno=sr_gameno
 and powername=sr_powername
;

-- Add attacking message
Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, sr_userno, Concat("You have performed a Space Blast using ",sr_nukes,Case When sr_nukes=1 Then " nuke." Else " nukes." End));

-- Set place holder for space blast report
Insert Into sp_message_queue (gameno, message) Values (sr_gameno, '**');

-- Get number of blanket hits
Set done=0;
Set sr_report=Concat(sf_fxml('AttPowername',sr_powername),sf_fxml('AttNukes',sr_nukes));
OPEN blanket;
read_loop: LOOP
    -- Get number of blanket slots
    FETCH FROM blanket INTO sr_def_userno, sr_def_powername, sr_slots, sr_def_lstars, sr_def_ksats;
    IF done THEN LEAVE read_loop; END IF;

    IF @sr_debug='X' THEN Select "Blanket", done, sr_def_userno, sr_def_powername, sr_slots, sr_def_lstars, sr_def_ksats; END IF;

    -- Add attacked message
	Insert Into sp_message_queue (gameno, userno, to_email, message)
	 Values (sr_gameno, sr_def_userno, -1, Concat("Your satellites have been targeted by warheads fired by ", sr_powername,"."));

    -- Stop when everyone has been evaluated
    Set i=1;

    -- Add redeploy and retaliations
    Call sr_4_attack_set(sr_gameno, 'SpaceBlast', sr_def_powername, null, null);

    -- Process each slots
    WHILE i <= sr_slots+sr_def_ksats DO
        Set r=Rand();
        -- Kill one nuke
        IF r < 0.4 THEN
            Update tmp_targets
            Set killed=killed+1, blanket_r=Least(Coalesce(blanket_r,1),r), blanket_n=blanket_n+1
            Where userno=sr_def_userno
            Limit 1
            ;
        ELSE
            Update tmp_targets
            Set blanket_r=Least(Coalesce(blanket_r,1),r), blanket_n=blanket_n+1
            Where userno=sr_def_userno
            Limit 1
            ;
        END IF;

        Set i=i+1;
    END WHILE;
	-- Compile report
	Select Concat(sr_report,sf_fxml('Powername',Concat(powername
                                                      ,sf_fxml('LStars',lstars)
                                                      ,sf_fxml('BlanketSlots',blanket)
                                                      ,sf_fxml('KSats',ksats)
                                                      ,sf_fxml('Hits',killed)
													  ))) 
    Into sr_report
    From tmp_targets 
	Where userno=sr_def_userno
	;
END LOOP;
CLOSE blanket;

IF @sr_debug!='N' THEN
    Select *, "Blanket TMP_TARGETS" From tmp_targets;
END IF;

-- See if it has worked
IF sr_nukes > (Select Sum(killed) From tmp_targets) THEN 
	Set sr_report=Concat(sr_report,sf_fxml('Result','Successful'));
	Update sp_resource Set lstars=0, ksats=0 Where gameno=sr_gameno;
	Call sr_check_lstar_slots(sr_gameno);
ELSE 
	Set sr_report=Concat(sr_report,sf_fxml('Result','Unsuccessful'));
END IF;

-- Add war head report to the queue
Update sp_message_queue Set message = sf_fxml('SPACEBLAST',sr_report) Where gameno=sr_gameno and message='**';

-- Add log message
Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name, sf_fxml('SUCCESS',sr_report));

-- Clean Up
Drop Table tmp_targets;

-- Move queue
Delete From sp_orders Where gameno=sr_gameno and userno=sr_userno and ordername in ('att_terr','def_terr','def_power','Action');
Update sp_orders Set order_code='Orders processed'
Where gameno=sr_gameno
 and userno=sr_userno
 and turnno=sr_turnno
 and phaseno=sr_phaseno
 and (order_code like 'Waiting%' or order_code='Orders processing')
;
Call sr_move_queue(sr_gameno);

-- */;
END sproc;
END
$$

Delimiter ;