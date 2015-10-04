use asupcouk_asup;
Drop procedure if exists sr_move_queue_build;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

DELIMITER $$

CREATE
PROCEDURE  asupcouk_asup . sr_move_queue_build  (sr_gameno INT)
BEGIN
sproc:BEGIN

-- Set up blank build orders
-- $Id: sr_move_queue_build.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_MOVE_QUEUE_BUILD";
DECLARE sr_turnno INT DEFAULT 0;
DECLARE sr_phaseno INT DEFAULT 0;
DECLARE last_userno INT;
DECLARE sr_userno INT;
DECLARE done INT DEFAULT 0;
DECLARE sr_order_xml TEXT DEFAULT '<BUILD>';
DECLARE sr_terrno INT DEFAULT 0;
DECLARE sr_terrname TEXT DEFAULT '';
DECLARE sr_terrtype TEXT DEFAULT '';

DECLARE terrs CURSOR FOR
Select b.build_userno, terrno, terrname, terrtype
From sv_map_build b
Join sp_orders o
On b.gameno=o.gameno and b.build_userno=o.userno and o.phaseno=5 and o.ordername='ORDSTAT' and o.order_code='Waiting for orders'
Where b.gameno=sr_gameno
Order By b.build_userno
;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

-- Check game is valid
IF (sr_gameno not in (Select gameno From sp_game Where phaseno=5)) THEN
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid game or phase</Reason><Game>",sr_gameno,"</Game></FAIL>"));
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Add blank buld orders for each Superpower
Set done=0;
Set last_userno=0;
OPEN terrs;
read_loop: LOOP
    FETCH FROM terrs INTO sr_userno, sr_terrno, sr_terrname, sr_terrtype;
    IF @sr_debug != 'N' THEN Select done, last_userno, sr_userno, sr_terrno, sr_terrname, sr_terrtype; END IF;

    -- Add order if not the first pass
    IF done or (last_userno > 0 and last_userno != sr_userno) THEN
        Insert Into sp_orders (gameno, turnno, phaseno, userno, ordername, order_code)
        Value (sr_gameno, sr_turnno, sr_phaseno, last_userno, 'SR_ORDERXML', Concat(sr_order_xml,'</BUILD>'))
        ;
    END IF;

    IF done THEN LEAVE read_loop; END IF;

    -- Action for swapping user number
    IF sr_userno != last_userno THEN
        -- Create new order
        Set sr_order_xml = Concat('<BUILD>'
                                 ,sf_fxml('Research'
                                         ,Concat(sf_fxml('strategic',Concat(sf_fxml('Amt',0),sf_fxml('Val',0)))
                                                ,sf_fxml('land',Concat(sf_fxml('Amt',0),sf_fxml('Val',0)))
                                                ,sf_fxml('water',Concat(sf_fxml('Amt',0),sf_fxml('Val',0)))
                                                ,sf_fxml('resource',Concat(sf_fxml('Amt',0),sf_fxml('Val',0)))
                                                ,sf_fxml('espionage',Concat(sf_fxml('Amt',0),sf_fxml('Val',0)))
                                                )
                                         )
                                 ,sf_fxml('Storage'
                                         ,Concat(sf_fxml('max_Minerals',0)
                                                ,sf_fxml('max_Oil',0)
                                                ,sf_fxml('max_Grain',0)
                                                )
                                         )
                                 ,sf_fxml('Strategic'
                                         ,Concat(sf_fxml('nukes',0)
                                                ,sf_fxml('lstars',0)
                                                ,sf_fxml('ksats',0)
                                                ,sf_fxml('neutron',0)
                                                )
                                         )
                                 );
        Set last_userno = sr_userno;
    END IF;

    -- Add in territories
    Set sr_order_xml = Concat(sr_order_xml
                             ,'<BuildTroops>'
                             ,sr_terrname
                             ,sf_fxml('Terrno',sr_terrno)
                             ,sf_fxml('Major',0)
                             ,sf_fxml('Minor',0)
                             ,'</BuildTroops>'
                             );


END LOOP;
CLOSE terrs;

-- /* */
END sproc;
END
$$

Delimiter ;
