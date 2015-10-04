use asupcouk_asup;
DROP PROCEDURE IF EXISTS sr_company_trading;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- ALTER TABLE `asupcouk_asup`.`sp_cards` ADD COLUMN `blocked` CHAR(1) NULL DEFAULT '' AFTER `running`;

DELIMITER $$

CREATE
PROCEDURE sr_company_trading(sr_gameno INT)
BEGIN
sproc:BEGIN

-- $Id: sr_company_trading.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_COMPANY_TRADING";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE sr_i INT DEFAULT 0;
DECLARE sr_n INT DEFAULT 0;
DECLARE sr_calced INT DEFAULT 0;
DECLARE prev_calced INT DEFAULT 0;
DECLARE done INT DEFAULT 0;

-- DECLARE companies CURSOR FOR
-- Select Distinct gameno, userno, owningUserno, terrno, powername, terrname From tmp_area;

-- DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Drop any temporary tables that might be handing around
Drop Temporary Table If Exists tmp_area;
Drop Temporary Table If Exists tmp_area1;

-- Create board with all company territories required
Create Temporary Table tmp_area As
Select  b.gameno
		,Coalesce(r.userno, b.userno) As userno
		,b.userno As owningUserno
		,b.terrno
		,Case When pl.terrtype=pw.terrtype Then 1 Else 0 End As calced
        ,Case When pl.terrtype=pw.terrtype Then 0 Else null End As cost
		,pw.terrtype As usertype
		,pl.terrtype
		,pl.terrname
From	sp_board b
Left Join sp_resource r
On 		r.gameno=b.gameno
		and r.userno=Case When b.userno=0 Then r.userno Else b.userno End
Left Join sp_powers pw On r.powername=pw.powername
Left Join sp_places pl On b.terrno=pl.terrno
Where 	b.gameno=sr_gameno
		and pl.terrtype != 'OCE'
;

-- Get initial counts done
Select Count(*), Sum(calced) Into sr_n, sr_calced From tmp_area;
IF @sr_debug!='N' THEN Select sr_i, sr_n, sr_calced; END IF;
IF @sr_debug='X' THEN
	Select * From tmp_area Order By terrname;
END IF;

dijkstra: WHILE prev_calced < sr_calced and sr_i < 1000 DO
	Drop Temporary Table If Exists tmp_area1;
	Create Temporary Table tmp_area1 As Select * From tmp_area;

	Update tmp_area1 f
	 Join sp_ocean_borders b On f.terrno=terrno_from
	 Join tmp_area t On t.terrno=terrno_to and t.gameno=f.gameno and t.userno=f.userno
	 Set 	t.calced=1
			,t.cost=f.cost+distance
	 Where	t.cost is null
			and f.calced=1
	;
	-- Get next counts
	Set prev_calced=sr_calced;
	Select Count(*), Sum(calced) Into sr_n, sr_calced From tmp_area;
	IF @sr_debug!='N' THEN Select sr_i, sr_n, sr_calced; END IF;
	IF @sr_debug='X' THEN
		Select * From tmp_area Order By terrname;
	END IF;

	Set sr_i=sr_i+1;
END WHILE;

Update 	sp_cards c
Join    sp_res_cards rc
Join 	tmp_area a
On 		c.gameno=sr_gameno
		and c.userno=a.owningUserno
		and c.cardno=rc.cardno
		and rc.terrno=a.terrno
Set 	c.blocked=Case When cost is not null Then 'Y' Else 'N' End
;
IF @sr_debug!='N' THEN Select *, 'Final Table', sr_i, sr_n, sr_calced From tmp_area; END IF;
Drop Temporary Table tmp_area;

END sproc;
END;
$$
DELIMITER ;

/*
Call sr_take_territory(201,'Red Sea','Africa',0,1);
Call sr_take_territory(201,'Mozambique','Europe',0,1);
Call sr_take_territory(201,'Straights of Malacca','Europe',0,1);
Select * From sv_companies Where gameno=201 and powername='South America';
Set @sr_debug='N';
Call sr_company_trading(201);
Set @sr_debug='N';
Select * From sv_companies Where gameno=201 and powername='Europe';
*/