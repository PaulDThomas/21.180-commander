/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
use asupcouk_asup;
DROP PROCEDURE IF EXISTS sr_ocean_borders;

DELIMITER $$

-- Procedure to recursively create (a temporary version of) the sp_ocean_borders table
-- This table include all sp_borders, plus links between all OCE/SEA territories
--  which are traversed by ocean (so can not be blocked) and a distance column

CREATE PROCEDURE sr_ocean_borders()
BEGIN
sproc:BEGIN

-- $Id: sp_ocean_borders.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_OCEAN_BORDERS";
DECLARE done_nodes INT DEFAULT 1;
DECLARE last_nodes INT DEFAULT 0;
DECLARE i INT DEFAULT 0;

-- Get all available territories for all powernames
-- Put into temporary tables
Drop Temporary Table If Exists tmp_start;
Drop Temporary Table If Exists tmp_src;
Drop Temporary Table If Exists tmp_dest;

-- Get available territories...
-- All Sea/Ocean territories 
-- Except Seas not next to an ocean
Create Temporary Table tmp_start As
Select Distinct p1.terrtype, p1.terrname, p1.terrno
From   sp_places p1
Left Join sp_border b On p1.terrno=b.terrno_from
Left Join sp_places p2 On p2.terrno=b.terrno_to
Where  (p1.terrtype='OCE' or p2.terrtype='OCE')
 and   Length(p1.terrtype)=3
;

Create Temporary Table tmp_start2 As Select * From tmp_start;
Create Temporary Table tmp_src As
Select  p1.terrtype As terrtype_from
        ,p1.terrname As terrname_from
        ,p1.terrno As terrno_from
        ,p2.terrno As terrno_to
        ,p2.terrname As terrname_to
        ,p2.terrtype As terrtype_to
        ,Case When p1.terrno=p2.terrno Then 0 Else null End As dist
From    tmp_start p1
        ,tmp_start2 p2
;
Drop Temporary Table tmp_start2;

-- Create copy for remerge
Create Temporary Table tmp_dest As Select * From tmp_src;

WHILE done_nodes > last_nodes and i < 20 DO
    Set last_nodes = done_nodes;

    Update tmp_src s
     Join sp_border b On b.terrno_from=s.terrno_to
     Join sp_places p On p.terrno=b.terrno_from
     Join tmp_dest d On s.terrno_from=d.terrno_from and b.terrno_to=d.terrno_to
    Set d.dist = s.dist+1
    Where s.dist=i and d.dist is null
     and ((d.terrtype_to='OCE' and i=0) or p.terrtype='OCE' or i=0)
    ;

    Drop Temporary Table tmp_src;
    Create Temporary Table tmp_src As
    Select * From tmp_dest
    ;

    Select i, done_nodes, last_nodes, from_unixtime(unix_timestamp()), terrname_from, terrname_to, dist
    From tmp_dest
    Where dist=i-1
    ;

    Set i=i+1;
    Select Count(dist) Into done_nodes From tmp_src;

END WHILE;

Select * From tmp_dest;
/* */
END sproc;
END;
$$
DELIMITER ;

DROP Temporary TABLE IF EXISTS tmp_start;
DROP Temporary TABLE IF EXISTS tmp_src;
DROP Temporary TABLE IF EXISTS tmp_dest;

Call sr_ocean_borders();

Drop Table If Exists sp_ocean_borders;
Create Table sp_ocean_borders As
Select Distinct terrno_from, terrno_to, dist as distance
From tmp_dest
Where dist > 1
;
Insert Into sp_ocean_borders
Select Distinct terrno_from, terrno_to, 1
From sp_border
;

ALTER TABLE `asupcouk_asup`.`sp_ocean_borders` ENGINE = InnoDB ;
ALTER TABLE `asupcouk_asup`.`sp_ocean_borders` ADD PRIMARY KEY (`terrno_from`, `terrno_to`) ;
Create Index sp_ocean_borders_from On sp_ocean_borders (terrno_from);
Create Index sp_ocean_borders_to On sp_ocean_borders (terrno_to);

Drop Temporary Table If Exists tmp_src;
Drop Temporary Table If Exists tmp_dest;

-- Check all previous borders are present, should be no results
Select b.terrno_from, b.terrno_to 
From sp_border b
Left Join sp_ocean_borders ob
On ob.terrno_from=b.terrno_from and b.terrno_to=ob.terrno_to and distance=1
Where ob.terrno_from is null
-- and b.terrno_from = 76
;

Select p1.terrname, p2.terrname, ob.distance
From sp_places p1
Left Join sp_ocean_borders ob On p1.terrno=ob.terrno_from
Left Join sp_places p2 On p2.terrno=ob.terrno_to
Where p1.terrname in ('Tokyo Bay','Persian Gulf')
Order By p1.terrname, distance
;
/* */
