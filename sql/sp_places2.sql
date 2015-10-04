/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
-- Script to add continent column to sp_places and populate it
-- $Id: sp_places2.sql 242 2014-07-13 13:48:48Z paul $

-- alter table sp_places add column continent char(15);

-- Europe
update sp_places set continent='Europe'
where terrno in (1,2,3,4,5,36,37,38,53,54,55,56,57,58);

-- Africa
update sp_places set continent='Africa'
where terrno in (17,18,19,20,60,89,90,91,92);

-- Asia
update sp_places set continent='Asia'
where terrno in (6,7,8,9,10,11,12,13,14,15,16,39,40,41,42,43,44,45,46,47,48,59,61,62,64,65,66,67,92);

-- Oceania
update sp_places set continent='Oceania'
where terrno in (49,50,51,52,63,68,69,70);

-- North America
update sp_places set continent='North America'
where terrno in (25,26,27,28,29,30,31,32,33,74,75,76,77,78,79,80);

-- South America
update sp_places set continent='South America'
where terrno in (21,22,23,24,34,35,71,72,73);

-- Ocean
update sp_places set continent='Ocean'
where terrtype='OCE';

-- Drawing
update sp_drawing set info=2
where terrno in (86,87,88) and x > 1000;


-- Change players table
ALTER TABLE `asupcouk_asup`.`sp_powers` ADD COLUMN `players` INT NOT NULL DEFAULT 6  AFTER `blue` ;
Update sp_powers
Set players = Case
               When powername='Arabia' Then 9
               When powername in ('Canada','Australia') Then 9
               When powername in ('Nuked','Neutron') Then 99
               Else 1
              End;
Insert Into sp_powers (powername, terrtype, red, green, blue, players)
Values ('Neutron','NETR',10,30,50,99);

-- Change users table
ALTER TABLE `asupcouk_asup`.`sp_users` ADD COLUMN `admin` VARCHAR(1) NULL DEFAULT 'N'  AFTER `last_hostname` ;

-- Add primary key to
ALTER TABLE asupcouk_asup.sp_orders add primary key (gameno, userno, turnno, phaseno, order_code);