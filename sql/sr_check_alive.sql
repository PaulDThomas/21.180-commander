use asupcouk_asup;
Drop procedure if exists sr_check_alive;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_check_alive` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Procedure to check that everyone is still in the game
-- Called from sr_move_queue
-- $Id: sr_check_alive.sql 253 2014-08-25 11:54:23Z paul $
DECLARE proc_name TEXT DEFAULT "SR_CHECK_ALIVE";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_vultureno INT DEFAULT 0;
DECLARE sr_powername TEXT;
DECLARE sr_vulturename TEXT;
DECLARE sr_terrtype CHAR(4);
DECLARE sr_sup_terrs INT DEFAULT 0;
DECLARE sr_own_sup_terrs INT DEFAULT 0;
DECLARE sr_nuked_sup_terrs INT DEFAULT 0;
DECLARE sr_taken_sup_terrs INT DEFAULT 0;
DECLARE sr_all_players INT DEFAULT 0;
DECLARE sr_dead_players INT DEFAULT 0;
DECLARE sr_messagexml TEXT;
DECLARE sr_mod DOUBLE DEFAULT 0;
DECLARE sr_terrname TEXT;
DECLARE sr_major INT DEFAULT 0;
DECLARE sr_minor INT DEFAULT 0;
DECLARE done INT DEFAULT 0;

DECLARE powers CURSOR FOR
Select r.powername, r.userno, pw.terrtype, count(pl.terrno), Sum(b.userno=r.userno), Sum(b.userno <= -9)
From sp_resource r
Left Join sp_powers pw On r.powername=pw.powername
Left Join sp_places pl On pw.terrtype=pl.terrtype
Left Join sp_board b On b.terrno=pl.terrno and r.gameno=b.gameno
Where r.gameno=sr_gameno
 and r.dead in ('N','S')
Group By r.powername, r.userno, pw.terrtype
Having Sum(b.userno=r.userno) = 0
;

-- To reassign territories, no Boomers are taken!
DECLARE terrs CURSOR FOR
Select terrname, Case When Length(terrtype)=4 Then major Else 0 End, minor
From sp_board b
Left Join sp_places p On b.terrno=p.terrno
Where p.terrtype != sr_terrtype
 and b.gameno=sr_gameno
 and b.userno=sr_userno
;

DECLARE vultures CURSOR FOR
Select b.userno, powername, Count(*)
From sp_board b
Left Join sp_resource r On r.gameno=b.gameno and r.userno=b.userno
Left Join sp_places p
On b.terrno=p.terrno
Where b.gameno=sr_gameno
 and b.userno > 0
 and terrtype=sr_terrtype
 and r.dead='N'
 and Exists(Select 1
            From sp_board b1, sp_powers pw1, sp_places p1
            Where pw1.powername=r.powername
             and pw1.terrtype=p1.terrtype
             and b1.terrno=p1.terrno
             and b1.userno=r.userno
			 and b1.gameno=b.gameno)
Group By 1, 2
Order by 2
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


-- Check game and phase
IF sr_gameno not in (Select gameno From sp_game) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid game or phase")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  )
                            )
                   )
            );
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Leave procedure if game has already ended 
IF sr_phaseno=9 THEN
    IF @sr_debug != 'N' THEN
        Select "Already finished, leaving", proc_name, sr_gameno, sr_turnno, sr_phaseno;
    END IF;
    LEAVE sproc;
END IF;

-- Leave procedure if there are MA orders outstanding
IF (Select Count(*) 
	From sp_orders 
    Where gameno=sr_gameno 
     and (ordername='MA_000' or ordername like 'MA_____R%')
    ) > 0 THEN
    IF @sr_debug != 'N' THEN
        Select *, "Outstanding MA orders, leaving", proc_name From sp_orders Where gameno=sr_gameno and phaseno=sr_phaseno;
    END IF;
    LEAVE sproc;
END IF;

-- See if there are any dead people and set them to S
OPEN powers;
read_ploop: LOOP
    FETCH FROM powers Into sr_powername, sr_userno, sr_terrtype, sr_sup_terrs, sr_own_sup_terrs, sr_nuked_sup_terrs;
    IF done THEN LEAVE read_ploop; END IF;
    -- Set dead to S on resource card until dead score is allocated
    Update sp_resource Set dead="S" Where gameno=sr_gameno and powername=sr_powername;
END LOOP;
CLOSE powers;
Set done=0;

-- Process dead people scores and vultures
OPEN powers;
read_loop: LOOP
    FETCH FROM powers Into sr_powername, sr_userno, sr_terrtype, sr_sup_terrs, sr_own_sup_terrs, sr_nuked_sup_terrs;

    -- Debug info
    IF done THEN LEAVE read_loop; END IF;
    IF @sr_debug!="N" THEN
        Select "Dead power", sr_powername, sr_userno, sr_terrtype, sr_sup_terrs, sr_own_sup_terrs, sr_nuked_sup_terrs;
    END IF;
    Set sr_messagexml = Concat("<DEADPOWER>"
                              ,sf_fxml("DeadPower",sr_powername)
                              ,sf_fxml("Territories",sr_sup_terrs)
                              ,sf_fxml("NukedTerritories",sr_nuked_sup_terrs)
                              );

    -- Set dead to S on resource card until dead score is allocated
    Update sp_resource Set dead="S" Where gameno=sr_gameno and powername=sr_powername;

    -- Clean up other tables
    Delete From sp_orders Where gameno=sr_gameno and userno=sr_userno;
    Delete From sp_lstars Where gameno=sr_gameno and userno=sr_userno;

    IF @sr_debug!='N' THEN
		Select b.userno, powername, Count(*)
		From sp_board b
		Left Join sp_resource r On r.gameno=b.gameno and r.userno=b.userno
		Left Join sp_places p
		On b.terrno=p.terrno
		Where b.gameno=sr_gameno
		 and b.userno > 0
		 and terrtype=sr_terrtype
		 and r.dead='N'
		 and Exists(Select 1
					From sp_board b1, sp_powers pw1, sp_places p1
					Where pw1.powername=r.powername
					 and pw1.terrtype=p1.terrtype
					 and b1.terrno=p1.terrno
					 and b1.userno=r.userno
					 and b1.gameno=b.gameno)
		Group By 1, 2
		Order by 2
		;
    END IF;

    -- Split resources
    OPEN vultures;
    inner_loop: LOOP
        FETCH FROM vultures Into sr_vultureno, sr_vulturename, sr_taken_sup_terrs;
        IF done THEN LEAVE inner_loop; END IF;

        -- Debug print and leave
        Set sr_mod = sr_taken_sup_terrs/(sr_sup_terrs-sr_nuked_sup_terrs);
        IF @sr_debug!="N" THEN
            Select "Vulture", sr_userno, sr_vultureno, sr_vulturename, sr_taken_sup_terrs, sr_mod, done;
        END IF;

        -- Add split of each resource
        Set sr_messagexml = Concat(sr_messagexml,"<Powername>",sr_vulturename);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'cash', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'max_minerals', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'max_oil', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'max_grain', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'minerals', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'oil', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'grain', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'nukes', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'lstars', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'ksats', sr_mod, sr_messagexml);
        Call sr_take_resource(sr_gameno, sr_userno, sr_vultureno, 'neutron', sr_mod, sr_messagexml);
        Set sr_messagexml = Concat(sr_messagexml,"</Powername>");

    END LOOP;
    CLOSE vultures;
    Set done=0;

    -- Split territories
    OPEN terrs;
    inner_loop2: LOOP
        FETCH FROM terrs Into sr_terrname, sr_major, sr_minor;

        -- Debug print and leave
        IF @sr_debug="X" THEN
            Select "Terrs", sr_terrname, sr_major, sr_minor, done;
        END IF;
        IF done THEN LEAVE inner_loop2; END IF;

        -- Get new powername
        Select new_powername Into sr_vulturename From (
        Select Coalesce(r2.powername,'Neutral') As new_powername, terrname
        From sp_board b2
        Left Join sp_places p2 On b2.terrno=p2.terrno
        Left Join sp_resource r2 On b2.gameno=r2.gameno and b2.userno=r2.userno
        Where b2.gameno=sr_gameno
         and p2.terrtype=sr_terrtype
         and r2.dead='N'
         Union
        Select "Neutral", "Extra"
        Order By rand()
        Limit 1
        ) a;

        -- Update territory, will also add a message to the queue
        Call sr_take_territory(sr_gameno, sr_terrname, sr_vulturename, sr_major, sr_minor);

    END LOOP;
    CLOSE terrs;
    Set done=0;

    -- Close the dead person report, and put it into everyones messages
    Set sr_messagexml = Concat(sr_messagexml,'</DEADPOWER>');
    Insert into sp_message_queue (gameno, message) Values (sr_gameno, sr_messagexml);

END LOOP;
CLOSE powers;

-- Add death score
Select Count(*), Sum(dead='Y') Into sr_all_players, sr_dead_players From sp_resource Where gameno=sr_gameno;
IF @sr_debug != 'N' THEN Select "CHECK ALIVE:", sr_all_players, sr_dead_players; END IF;
Insert Into sp_score (xgameno, userno, score, finish_uts, players, alive_players, powername)
Select gameno, userno
       ,Case When mia >= 3 and sr_turnno <= 3 Then 0 Else sr_dead_players+1 End
       ,unix_timestamp()
       ,sr_all_players
       ,sr_dead_players+1
       ,powername
From sp_resource
Where gameno=sr_gameno
 and dead='S'
;
-- Clean up
Delete From sp_boomers Where gameno=sr_gameno and userno in (Select userno From sp_resource Where dead='S' and gameno=sr_gameno);
Update sp_resource Set dead='Y', minerals=0, oil=0, grain=0, max_minerals=0, max_oil=0, max_grain=0, lstars=0, nukes=0, ksats=0, neutron=0, cash=0  Where gameno=sr_gameno and dead='S';
Call sr_check_lstar_slots(sr_gameno);

-- Winning
IF sr_dead_players = sr_all_players-1
 THEN
    Insert Into sp_score (xgameno, userno, score, finish_uts, players, alive_players, powername)
    Select gameno, userno
           ,sr_all_players+4
           ,unix_timestamp()
           ,sr_all_players
           ,sr_dead_players
           ,powername
    From sp_resource
    Where gameno=sr_gameno
     and dead='N'
    ;
    Select userno, powername Into sr_userno, sr_powername From sp_resource Where gameno=sr_gameno and dead='N';
    Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, sr_userno, "Congratulations, you have successfully defeated your last opponent.  You are the winner of the game");
    Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, 0, Concat("The game has been won by ",sr_powername));
    Update sp_game Set phaseno=9, deadline_uts=null Where gameno=sr_gameno;
    Delete From sp_orders Where gameno=sr_gameno;
    Call sr_message_queue(sr_gameno);
ELSEIF sr_dead_players = sr_all_players THEN
    Insert Into sp_message_queue (gameno, userno, message) Values (sr_gameno, 0, Concat("Nobody gas won this game"));
    Update sp_game Set phaseno=9, deadline_uts=null Where gameno=sr_gameno;
    Delete From sp_orders Where gameno=sr_gameno;
    Call sr_message_queue(sr_gameno);
END IF;

/* */
END sproc;
END
$$

Delimiter ;
/*
Delete From sp_old_orders;
Delete From sp_messages;
Delete From sp_message_queue;
Delete From sp_score;

Update sp_resource Set dead='N', mia=1, minerals=12, oil=24, grain=36 Where gameno=48 and powername='Arabia';
Call sr_take_territory(48, 'Peru', 'Arabia', 1, 1);

Set @sr_debug='N';
Call sr_check_alive(48);

Select * From sp_score;

select * from sp_message_queue;
*/
