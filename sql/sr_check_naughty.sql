use asupcouk_asup;
Drop procedure if exists sr_check_naughty;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_check_naughty` (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Procedure to check that no one is playing two or more powers
-- $Id: sr_check_naughty.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_CHECK_NAUGHTY";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE failXML TEXT DEFAULT '';
DECLARE sr_userno INT DEFAULT 0;
DECLARE sr_powername TEXT;
DECLARE sr__utma TEXT;
DECLARE done INT;

DECLARE naughty CURSOR FOR
Select r.userno, r.powername, r.__utma
From sp_resource r
 ,(select gameno, __utma from sp_resource r2 where __utma is not null and __utma != '' and naughty='N' group by 1, 2 having count(*)>1) b
Where r.gameno=b.gameno
 and r.__utma=b.__utma
 and r.gameno=sr_gameno
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game and phase
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
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

OPEN naughty;
read_loop: LOOP
    FETCH FROM naughty Into sr_userno, sr_powername, sr__utma;

    IF done THEN LEAVE read_loop; END IF;
    IF failXML not like Concat('%',sr__utma,'%') THEN Set failXML = Concat(failXML,sf_fxml('UTMA',sr__utma)); END IF;
    Set failXML = Concat(failXML, sf_fxml('BAD',Concat(sr_powername, ' - ',sr_userno)));
END LOOP;
CLOSE naughty;

IF @sr_debug!='N' THEN Select failXML; END IF;

-- Add to OLD_ORDERS if someone comes up...
IF failXML != '' THEN
    Insert into sp_old_orders (gameno, turnno, phaseno, ordername, order_code)
     Values (sr_gameno, sr_turnno, sr_phaseno, proc_name
            ,Concat(sf_fxml("FAIL",failXML))
            );
END IF;

/* */
END sproc;
END
$$

Delimiter ;
/*
Delete From sp_old_orders;

update sp_resource set __utma=SUBSTRING(MD5(RAND()) FROM 1 FOR 10) where gameno=48;
update sp_resource set __utma="CHEAT" where gameno=48 and userno > 3400;
update sp_resource set __utma="NICECHEAT" where gameno=48 and userno < 3239;

Select r.userno, r.powername, r.__utma
From sp_resource r
 ,(select gameno, __utma from sp_resource r2 where __utma is not null and __utma != '' group by 1, 2 having count(*)>1) b
Where r.gameno=b.gameno
 and r.__utma=b.__utma
 and r.gameno=48
;

Select userno, powername, __utma from sp_resource where gameno=48;

call sr_check_naughty(48);
call sr_check_naughty(49);
*/