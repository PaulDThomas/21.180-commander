use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_new_game;

DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_new_game` (sr_debug TEXT)
BEGIN
sproc:BEGIN

-- Procedure to create new games
-- $Id: sr_new_game.sql 281 2015-04-20 05:14:50Z paul $
DECLARE proc_name TEXT DEFAULT "SR_NEW_GAME";
DECLARE done INT DEFAULT 0;
DECLARE sr_players INT DEFAULT 0;
DECLARE sr_advance_uts INT DEFAULT 0;
DECLARE sr_gameno INT DEFAULT 0;
DECLARE sr_powername TEXT;
DECLARE sr_terrtype TEXT;
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_cardno INT DEFAULT 0;
DECLARE sr_terrno INT DEFAULT 0;
DECLARE xml_orders TEXT;
DECLARE x_terrs INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
DECLARE j INT DEFAULT 0;

DECLARE powers CURSOR FOR
Select powername
From sp_powers
Where players <= sr_players
Order By rand()
;

DECLARE resource CURSOR FOR
Select r.powername, userno, terrtype
From sp_resource r
Left Join sp_powers p On r.powername=p.powername
Where gameno = sr_gameno
Order By rand()
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;


-- No error checks, just do nothing if the conditions are not right
-- Only create one game, assume the script will run again soon if there is a queue

-- Get current state of game queue
Select p.players, p.advance_uts
Into sr_players, sr_advance_uts
From sp_newq q, sp_newq_params p
Where q.players=p.players
 and q.advance_uts=p.advance_uts
Group By p.players, p.advance_uts
Having count(*) >= p.players
Limit 1
;

-- Stop if there are no rows
IF (sr_players = 0 or sr_advance_uts = 0) THEN
    Leave sproc;
END IF;

-- Debug
IF sr_debug != 'N' THEN Select "Found new game:" As '', sr_players, sr_advance_uts; END IF;

-- Create game entry
Select Coalesce(Max(gameno)+1,1) From sp_game Into sr_gameno;
Insert Into sp_game (gameno, advance_uts, mapmod, nuke_tech_level, lstar_tech_level, ksat_tech_level
                    ,neutron_tech_level, blockade, siege, phase2_type, boomers, liquid_asset_percent
                    ,company_restart_cost, winter_type, auto_force, tank_tech_level, boomer_tech_level
                    ,white_comms_level, grey_comms_level, black_comms_level, yellow_comms_level, fortuna_flag
                    )
 Select sr_gameno   ,advance_uts, mapmod, nuke_tech_level, lstar_tech_level, ksat_tech_level
                    ,neutron_tech_level, blockade, siege, phase2_type, boomers, liquid_asset_percent
                    ,company_restart_cost, winter_type, auto_force, tank_tech_level, boomer_tech_level
                    ,white_comms_level, grey_comms_level, black_comms_level, yellow_comms_level, fortuna_flag
 From sp_newq_params
 Where players=sr_players
  and advance_uts=sr_advance_uts
 ;
-- Add new deadline
Update sp_game
Set deadline_uts = unix_timestamp()+Case When sr_advance_uts >= 86400 Then 5*86400 Else sr_advance_uts End
Where gameno=sr_gameno
;

-- Debug
IF sr_debug != 'N' THEN Select *, "New Game" From sp_game Where gameno=sr_gameno; END IF;

-- Add Superpowers randomly
Set done=0;
OPEN powers;
Set i=1;
read_loop: LOOP
    FETCH FROM powers Into sr_powername;
    IF done or i > sr_players THEN LEAVE read_loop; END IF;

    -- Get userno to match with random power
    Select userno Into sr_userno From sp_newq Where players=sr_players and advance_uts=sr_advance_uts Order By rand() Limit 1 ;

    -- Debug
    IF sr_debug = 'X' THEN Select "Adding player:" As '', sr_userno, sr_powername; END IF;

    -- Create resource card
    Insert Into sp_resource (gameno, userno, powername) Values (sr_gameno, sr_userno, sr_powername);

    -- Remove user from queue
    Delete From sp_newq Where players=sr_players and advance_uts=sr_advance_uts and userno=sr_userno;
    Set i=i+1;

END LOOP;
CLOSE powers;

-- Update holiday entitlement
Update sp_resource Set holiday=(Select holiday From sp_newq_params Where players=sr_players and advance_uts=sr_advance_uts) Where gameno=sr_gameno;

-- Remove main queue entry
IF ((Select count(*) From sp_newq Where players=sr_players and advance_uts=sr_advance_uts)=0) THEN
	Delete From sp_newq_params Where players=sr_players and advance_uts=sr_advance_uts;
END IF;

-- Debug
IF sr_debug != 'N' THEN Select *, "Resource Table" From sp_resource Where gameno=sr_gameno; END IF;

-- Set up board and cards
Insert Into sp_board (gameno, terrno) Select sr_gameno, terrno From sp_places;
Insert Into sp_cards (gameno, cardno) Select sr_gameno, cardno From sp_res_cards;


-- Update board for home territories
UPDATE sp_board b, sp_places p, sp_powers pw, sp_resource r
Set b.userno=r.userno, b.minor=1
Where b.gameno=sr_gameno
 and b.gameno=r.gameno
 and p.terrno=b.terrno
 and r.powername=pw.powername
 and pw.terrtype=p.terrtype
;


-- Loop through companies
Set done=0;
OPEN resource;
read_loop: LOOP
    -- Get powername and userno
    FETCH FROM resource Into sr_powername, sr_userno, sr_terrtype;
    IF done THEN LEAVE read_loop; END IF;

    -- Add in extra company cards
    Set x_terrs = Case When sr_players<=6 Then 3 When sr_players<=8 Then 2 Else 1 End;

    Set i=0;
    WHILE i < 6 DO
        -- Select random card
        Select c.cardno Into sr_cardno
        From sp_cards c, sp_res_cards rc, sp_board b
        Where c.gameno=sr_gameno
         and ( b.userno=(Case When i < x_terrs Then 0 Else sr_userno End)
               or b.userno = sr_userno
              )
         and rc.terrtype=(Case When i >= x_terrs Then sr_terrtype Else rc.terrtype End)
         and rc.terrtype not in (Select terrtype From sp_resource r, sp_powers p Where r.gameno=sr_gameno and r.powername=p.powername and r.userno!=sr_userno)
         and c.cardno=rc.cardno
         and b.gameno=c.gameno
         and rc.terrno=b.terrno
         and c.userno=0
        Order By rand()
        Limit 1
        ;

        -- Debug
        IF sr_debug = 'C' THEN Select "Found card:" As '', x_terrs, sr_gameno, sr_userno, sr_cardno; END IF;

        -- Update card
        Update sp_cards c, sp_res_cards rc, sp_board b
        Set c.userno = sr_userno
         , b.userno = sr_userno
         , b.minor = 1
        Where c.gameno=sr_gameno
         and c.cardno=sr_cardno
         and rc.cardno=sr_cardno
         and b.gameno=sr_gameno
         and rc.terrno=b.terrno
        ;
        Set i=i+1;
    END WHILE;
END LOOP;
CLOSE resource;

-- Debug
IF sr_debug != 'N' THEN
    Select "Companies assigned:" as '', powername, terrtype, count(*)
    From sp_cards c, sp_resource r, sp_res_cards rc
    Where r.gameno=sr_gameno and c.gameno=r.gameno and c.userno=r.userno and c.cardno=rc.cardno
    Group By 1, 2, 3;
END IF;

-- Add navy to available sea territories
Update sp_board b, sv_map_build m
Set b.userno=build_userno, b.minor=1
Where b.gameno=sr_gameno
 and b.gameno = m.gameno
 and b.terrno = m.terrno
 and build_userno > 0
;

-- Debug
IF sr_debug != 'N' THEN Select * From sv_map Where gameno=sr_gameno; END IF;

-- Set market
Insert Into sp_market (gameno, minerals_level, oil_level, grain_level)
Values (sr_gameno
       ,Ceil(Rand()*6)+Ceil(Rand()*6)
       ,Ceil(Rand()*6)+Ceil(Rand()*6)
       ,Ceil(Rand()*6)+Ceil(Rand()*6)
       );

-- Create Initial resource orders
Insert Into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, 0, 0, 'SR_ORDERXML', Concat(sf_fxml('Minerals',3),sf_fxml('Oil',3),sf_fxml('Grain',3))
From sp_resource
Where gameno=sr_gameno
;

-- Add on random forces orders
Set done=0;
OPEN resource;
read_loop: LOOP
    -- Get powername and userno
    FETCH FROM resource Into sr_powername, sr_userno, sr_terrtype;

    IF sr_debug = 'T' THEN Select "Adding terr orders: ", sr_powername, sr_userno, sr_terrtype, done; END IF;
    IF done THEN LEAVE read_loop; END IF;

    Set i=0;
    WHILE i < 10 DO
        Select b.terrno Into sr_terrno
        From sp_board b, sp_places p
        Where gameno=sr_gameno and userno=sr_userno and b.terrno=p.terrno and Length(p.terrtype)=4
        Order By Rand()
        Limit 1
        ;

        -- Debug
        IF sr_debug = 'T' THEN
            Select "Random territory:" As '', sr_terrno, sr_userno;
        END IF;

        IF i=0 THEN
            Update sp_orders
            Set order_code = Concat(order_code, sf_fxml('Major',sr_terrno))
            Where gameno=sr_gameno and userno=sr_userno and ordername='SR_ORDERXML'
            ;
        ELSE
            Update sp_orders
            Set order_code = Concat(order_code, sf_fxml(Concat('Minor',i),sr_terrno))
            Where gameno=sr_gameno and userno=sr_userno and ordername='SR_ORDERXML'
            ;
        END IF;
        Set i=i+1;

    END WHILE;

END LOOP;
CLOSE resource;

-- Close off initial orders
Update sp_orders
Set order_code=sf_fxml('INITIAL',order_code)
Where gameno=sr_gameno
 and ordername='SR_ORDERXML'
;

-- Debug
IF sr_debug != 'N' THEN Select * From sp_orders Where gameno=sr_gameno; END IF;

-- Add status orders
Insert into sp_orders (gameno, userno, turnno, phaseno, ordername, order_code)
Select gameno, userno, 0, 0, 'ORDSTAT', 'Waiting for orders' From sp_resource
Where gameno=sr_gameno
;

-- Update randgen
Update sp_resource Set randgen=SUBSTRING(MD5(RAND()) FROM 1 FOR 10) Where gameno=sr_gameno;

-- Add welcome message
Insert Into sp_messages (gameno, userno, to_email, message)
Select gameno, userno, -1, Concat('Welcome to the game.  Your superpower is ',powername,'.\r\n'
                                 ,'Your first task is to places 9 armies or navies, 1 tank and 9 resources.\r\n'
                                 ,'Good Luck!')
From sp_resource
Where gameno=sr_gameno
;

/* */
END sproc;
END
$$

Delimiter ;
/*
Delete From sp_old_orders;
Delete From sp_messages;
Delete From sp_message_queue;
Delete From sp_newq;
Delete from sp_newq_params;

Set @lg = 197;
Delete From `sp_orders` Where gameno>@lg;
Delete From `sp_old_orders` Where gameno>@lg;
Delete From `sp_messages` Where gameno>@lg;
Delete From `sp_resource` Where gameno>@lg;
Delete From `sp_board` Where gameno>@lg;
Delete From `sp_lstars` Where gameno>@lg;
Delete From `sp_cards` Where gameno>@lg;
Delete From `sp_market` Where gameno>@lg;
Delete From `sp_game` Where gameno>@lg;

Insert into sp_newq_params (players, advance_uts,white_comms_level,grey_comms_level,black_comms_level,yellow_comms_level) values (4,1,1,2,3,4);
Insert into sp_newq (players, advance_uts, userno) values (4,1,3227),(4,1,3238),(4,1,3394),(4,1,3335);

Select * from sp_newq_params;
Select * from sp_newq;

call sr_new_game('Y');

select * from sp_game where gameno>@lg;
*/