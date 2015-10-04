use asupcouk_asup;
Drop procedure if exists sr_4_warheads;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_4_warheads` (sr_gameno INT
                                          ,sr_powername TEXT
                                          ,sr_warhead_array TEXT
                                          )
BEGIN
sproc:BEGIN

/*
sr_warhead_array
<TARGET>
    <terrname>terrname</terrname>
    <nuke>nukes</nuke>
    <neutron>neutrons<neuton>
</TARGET>
<TARGET>
    ...
</TARGET>
*/

-- $Id: sr_4_warheads.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_4_WARHEADS";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_avail_nukes INT Default 0;
DECLARE sr_avail_neutron INT Default 0;
DECLARE sr_targets INT Default 0;
DECLARE i INT Default 0;
DECLARE r DOUBLE Default 0;
DECLARE sr_terrname TEXT;
DECLARE sr_terrno INT Default 0;
DECLARE sr_major INT Default 0;
DECLARE sr_minor INT Default 0;
DECLARE sr_nukes INT Default 0;
DECLARE sr_neutron INT Default 0;
DECLARE sr_def_userno INT Default 0;
DECLARE sr_def_powername TEXT;
DECLARE sr_blanket_slots INT Default 0;
DECLARE sr_blanket_hits INT Default 0;
DECLARE sr_slots INT Default 0;
DECLARE sr_hits INT Default 0;
DECLARE done INT DEFAULT 0;
DECLARE sr_report TEXT Default '';
DECLARE sr_result TEXT;
DECLARE sr_retaliation INT Default 0;
DECLARE sr_ret_userno INT Default 0;
DECLARE sr_neutroned_troops INT Default 0;

-- Declare cursors for results
DECLARE blanket CURSOR FOR Select Distinct userno, powername, blanket From tmp_targets;
DECLARE targetted CURSOR FOR Select terrno, terrname, nukes, neutron, blanket_n, killed, slots, killed, powername, major, minor From tmp_targets;

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
Select userno, nukes, neutron
Into sr_userno, sr_avail_nukes, sr_avail_neutron
From sp_resource
Where gameno=sr_gameno and powername=sr_powername;

-- Check right power is processing
IF sr_userno = (Select userno From sp_orders
                Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
                      and ordername = 'MA_000'
                      and order_code like 'Waiting for retaliation%') THEN
    -- Set retaliation variables
    Select 1, order_code
    Into sr_retaliation, sr_ret_userno
    From sp_orders
    Where gameno=sr_gameno and turnno=sr_turnno and phaseno=4
          and ordername='MA_000_user'
    ;
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
call sr_check_lstar_slots(sr_gameno);

-- Create empty target table
Drop Temporary Table If Exists tmp_targets;
Create Temporary Table tmp_targets (terrname TEXT
                                   ,terrno INT
                                   ,major INT
                                   ,minor INT
                                   ,nukes INT
                                   ,neutron INT
                                   ,killed INT Default 0
                                   ,powername TEXT
                                   ,userno INT
                                   ,blanket INT Default 0
                                   ,blanket_n INT Default 0
                                   ,blanket_r DOUBLE
                                   ,slots INT
                                   ,slots_n INT Default 0
                                   ,slots_r DOUBLE
                                   ,random_order DOUBLE
                                   );

-- Count number of targets
Set sr_targets = ExtractValue(sr_warhead_array,'Count(/TARGET)');
-- Check there are targets
IF Coalesce(sr_targets,0) = 0 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>No targets, check XML</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sr_warhead_array
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;
Set i=1;

IF @sr_debug!='N' THEN Select sr_targets; END IF;

-- Check enough nukes and neutrons are available
IF ExtractValue(sr_warhead_array,'Sum(/TARGET/nuke)') > sr_avail_nukes or
   ExtractValue(sr_warhead_array,'Sum(/TARGET/neutron)') > sr_avail_neutron THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>Not enough warheads</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sf_fxml("AvailableNukes",sr_avail_nukes)
                  ,sf_fxml("AvailableNeutron",sr_avail_neutron)
                  ,sf_fxml("Nukes",ExtractValue(sr_warhead_array,'Sum(/TARGET/nuke)'))
                  ,sf_fxml("Neutron",ExtractValue(sr_warhead_array,'Sum(/TARGET/neutron)'))
                  ,"</FAIL>"));
    LEAVE sproc;
END IF;

-- Add values into the targets table
WHILE i <= sr_targets DO
    -- Check all territories are valid, check enough nukes / neutrons are available
    Insert Into tmp_targets (terrname, nukes, neutron, random_order)
    Select ExtractValue(sr_warhead_array,'/TARGET[$i]/terrname')
           ,Coalesce(ExtractValue(sr_warhead_array,'/TARGET[$i]/nuke'), 0)
           ,Coalesce(ExtractValue(sr_warhead_array,'/TARGET[$i]/neutron'), 0)
           ,rand()
    ;
    Set i=i+1;
END WHILE;

-- Look at target table
IF @sr_debug!='N' THEN Select * from tmp_targets; END IF;

-- Check all territories are valid
IF (Select Count(*) From tmp_targets t
    Left Join sp_places p On t.terrname=p.terrname
    Left Join sp_board b On b.terrno=p.terrno and b.gameno=sr_gameno
    Where b.userno is null or b.userno <= -9 or (sr_retaliation > 0 and b.userno!=sr_ret_userno)
    ) > 0 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
           ,Concat("<FAIL><Reason>One or more invalid territory names</Reason>"
                  ,sf_fxml("Powername",sr_powername)
                  ,sr_warhead_array
                  ,"</FAIL>"));
    Drop Table tmp_targets;
    LEAVE sproc;
END IF;

-- Get protected slots
Update tmp_targets t
Left Join (Select p.terrname, b.userno, Count(l.terrno) As slots, p.terrno, b.major, b.minor, r.powername
           From sp_places p
           Left Join sp_board b On p.terrno=b.terrno and b.gameno=sr_gameno
           Left Join sp_resource r On b.userno=r.userno and b.gameno=r.gameno
           Left Join sp_lstars l On l.terrno=p.terrno and l.gameno=b.gameno
           Group By p.terrname, b.userno
           ) x On t.terrname=x.terrname
Set t.userno=x.userno, t.slots=x.slots, t.terrno=x.terrno, t.major=x.major, t.minor=x.minor, t.powername=x.powername
;

-- Get number of blanket slots
Update tmp_targets t
Left Join (Select l.userno, Count(l.terrno) As blanket
           From sp_lstars l
           Where l.gameno=sr_gameno
            and l.terrno=0
           Group By l.userno
           ) x On t.userno=x.userno
Set t.blanket=x.blanket
;

-- Remove warheads from resource card
Update sp_resource
Set nukes = nukes - ExtractValue(sr_warhead_array,'Sum(/TARGET/nuke)')
    ,neutron = neutron - ExtractValue(sr_warhead_array,'Sum(/TARGET/neutron)')
Where gameno=sr_gameno
 and powername=sr_powername
;

-- Add attacking message
Set done=0;
Set i=1;
OPEN targetted;
read_loop: LOOP
    FETCH FROM targetted INTO sr_terrno, sr_terrname, sr_nukes, sr_neutron, sr_blanket_slots, sr_blanket_hits, sr_slots, sr_hits, sr_def_powername, sr_major, sr_minor;

    -- Stop when everyone has been evaluated
    IF done THEN LEAVE read_loop; END IF;
    -- Build string of targetted territories
    If i=1 THEN
        Set sr_report = sr_terrname;
    ELSEIF i=2 THEN
        Set sr_report = Concat(sr_report," and ",sr_terrname);
    ELSE
        Set sr_report = Concat(Substr(sr_report,1,Locate(' and ',sr_report)-1)
                              ,", ",sr_terrname
                              ," and "
                              ,Substring(sr_report,Locate(' and ',sr_report)+5)
                              );
    END IF;
    Set i=i+1;
END LOOP;
CLOSE targetted;
Insert Into sp_message_queue (gameno, userno, message)
 Values (sr_gameno, sr_userno, Concat("You have fired warheads at ",sr_report,"."));

-- Get number of blanket hits
Set done=0;
OPEN blanket;
read_loop: LOOP
    -- Get number of blanket slots
    FETCH FROM blanket INTO sr_def_userno, sr_def_powername, sr_slots;
    IF @sr_debug!='N' THEN Select "Blanket", done, sr_def_userno, sr_def_powername, sr_slots; END IF;

    -- Add attacked message
    IF 0=(Select Count(*) From sp_message_queue Where gameno=sr_gameno and userno=sr_def_userno and message=Concat("You have been targeted by warheads fired by ", sr_powername, ".")) THEN
        Insert Into sp_message_queue (gameno, userno, to_email, message)
         Values (sr_gameno, sr_def_userno, -1, Concat("You have been targeted by warheads fired by ", sr_powername,"."));
    END IF;
    -- Stop when everyone has been evaluated
    IF done THEN LEAVE read_loop; END IF;
    Select 1, 0 Into i, sr_hits;
    -- Process each slots
    WHILE i <= sr_slots DO
        Set r=Rand();
        -- Kill one nuke
        IF r < 0.25 THEN
            Update tmp_targets
            Set killed=killed+1, blanket_r=r, blanket_n=blanket_n+1
            Where userno=sr_def_userno
             and killed < nukes+neutron
            Order By rand()
            Limit 1
            ;
        ELSE
            Update tmp_targets
            Set blanket_r=Least(Coalesce(blanket_r,1),r), blanket_n=blanket_n+1
                Where userno=sr_def_userno
             and killed < nukes+neutron
            Order By rand()
            Limit 1
            ;
        END IF;

        Set i=i+1;
    END WHILE;
END LOOP;
CLOSE blanket;

IF @sr_debug!='N' THEN
    Select *, "Blanket TMP_TARGETS" From tmp_targets;
END IF;

-- Set place holder for warhead report
Insert Into sp_message_queue (gameno, message) Values (sr_gameno, '**');

-- Cycle through each target and resolve
Set sr_report='';
Set done=0;
OPEN targetted;
read_loop: LOOP
    FETCH FROM targetted INTO sr_terrno, sr_terrname, sr_nukes, sr_neutron, sr_blanket_slots, sr_blanket_hits, sr_slots, sr_hits, sr_def_powername, sr_major, sr_minor;
    IF @sr_debug!='N' THEN Select "Targetted", done, sr_terrno, sr_terrname, sr_nukes, sr_neutron, sr_blanket_slots, sr_blanket_hits, sr_slots, sr_hits, sr_def_powername, sr_major, sr_minor; END IF;

    -- Stop when everyone has been evaluated
    IF done THEN LEAVE read_loop; END IF;
    Set i = 1;
    -- Add redeploy and retaliations
    Call sr_4_attack_set(sr_gameno, 'Warhead', sr_def_powername, sr_terrname, null);
    -- Process each slot
    WHILE i <= sr_slots DO
        Set r=Rand();
        Set sr_hits = sr_hits + Case
                                 When r<0.1 Then 3
                                 When r<0.4 Then 2
                                 When r<0.8 Then 1
                                 Else 0
                                End
        ;
        Set i=i+1;
    END WHILE;
    -- See whether any warheads are left
    IF sr_hits < sr_nukes THEN
        Call sr_take_territory(sr_gameno, sr_terrname, 'Nuke', 0, 0);
        Set sr_result = 'Nuked';
    ELSEIF sr_hits < sr_nukes+sr_neutron THEN
        -- Remove up to 6 units
        Set sr_neutroned_troops = Ceil(Rand()*6)+1;
        Set sr_minor = Greatest(sr_minor-sr_neutroned_troops,0);
        Set sr_major = Greatest(0,Least(sr_major+sr_minor-sr_neutroned_troops,sr_major));
        Call sr_take_territory(sr_gameno, sr_terrname, 'Neutron', sr_major, sr_minor);
        -- Set ROP for attacking power
        Update sp_board Set passuser = sr_userno Where gameno=sr_gameno and terrno=sr_terrno;
        Set sr_result = 'Neutroned';
    ELSE
        Set sr_result = 'Safe';
    END IF;
    -- Add to warhead report
    Set sr_report = Concat(sr_report
                          ,'<TARGET>'
                          ,sf_fxml('Terrname',sr_terrname)
                          ,sf_fxml('Owner',sr_def_powername)
                          ,sf_fxml('Nukes',sr_nukes)
                          ,sf_fxml('Neutron',sr_neutron)
                          ,sf_fxml('NeutronedTroops',sr_neutroned_troops)
                          ,sf_fxml('BlanketSlots',sr_blanket_slots)
                          ,sf_fxml('BlanketHits',sr_blanket_hits)
                          ,sf_fxml('TargettedSlots',sr_slots)
                          ,sf_fxml('TargettedHits',sr_hits)
                          ,sf_fxml('Result',sr_result)
                          ,'</TARGET>'
                          );
END LOOP;
CLOSE targetted;

IF @sr_debug!='N' THEN
    Select *, "Final TMP_TARGETS" From tmp_targets;
END IF;

-- Add war head report to the queue
Update sp_message_queue
Set message = Concat('<WARHEADS>'
                    ,sf_fxml('AttPowername',sr_powername)
                    ,sr_report
                    ,'</WARHEADS>'
                    )
Where gameno=sr_gameno and message='**';

-- Add log message
Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name, sf_fxml('SUCCESS',sr_report));

-- Clean Up
Drop Table tmp_targets;

-- Check for nuclear winter
Call sr_is_it_winter(sr_gameno);

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

-- /* */
END sproc;
END
$$

Delimiter ;