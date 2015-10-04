use asupcouk_asup;
Drop procedure if exists sr_is_it_winter;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_is_it_winter` (sr_gameno INT)
BEGIN
sproc:BEGIN

DECLARE sr_nukes INT Default 0;
DECLARE sr_chance INT Default 0;
DECLARE sr_roll INT Default 0;
DECLARE sr_ctn TEXT;
DECLARE i INT Default 0;

-- Check game
If sr_gameno not in (Select gameno From sp_game Where phaseno < 9) Then
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, "SR_IS_IT_WINTER", Concat("<FAIL><Reason>Invalid Game</Reason><Gameno>",sr_gameno,"</Gameno></FAIL>"));
    Leave sproc;
End If;

-- Count territories
Select Sum(Case
            When userno=-9 and winter_type like '%Nuclear%' Then 1
            When userno=-10 and winter_type like '%Neutron%' Then 1
            Else 0
           End) as terrs
Into sr_nukes
From   sp_board b
Left Join sp_game g On b.gameno=g.gameno
Where  b.gameno=sr_gameno
;
Set sr_chance = Greatest(0,sr_nukes-12);

-- Roll the di
Set sr_roll = Ceil(Rand()*6);

-- Pass the results
If sr_chance = 0 Then
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Value (sr_gameno, 'SR_IS_IT_WINTER', Concat('<NoChance><Nukes>',sr_nukes,'</Nukes><Chance>',sr_chance,'</Chance><Roll>',sr_roll,'</Roll></NoChance>'));
ElseIf sr_roll >= sr_chance Then
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Value (sr_gameno, 'SR_IS_IT_WINTER', Concat('<NoWinter><Nukes>',sr_nukes,'</Nukes><Chance>',sr_chance,'</Chance><Roll>',sr_roll,'</Roll></NoWinter>'));
Else
    -- It must be winter
    Insert Into sp_old_orders (gameno, ordername, order_code)
    Value (sr_gameno, 'SR_IS_IT_WINTER', Concat('<WinterDescends><Nukes>',sr_nukes,'</Nukes><Chance>',sr_chance,'</Chance><Roll>',sr_roll,'</Roll></WinterDescends>'));
    -- Set all territories to nuked, one by one....
    Set sr_ctn=(Select terrname
                From sp_board b
                     ,sp_places p
                Where gameno=sr_gameno
                 and p.terrno=b.terrno
                 and userno not in (-9,-10)
                Order by terrname desc
                Limit 1
                );
	WHILE sr_ctn is not null and i<1000 DO
		Set i=i+1;
		IF @sr_debug!='N' THEN
			Select "Nuking ",sr_ctn,i;
		END IF;
        Call sr_take_territory(sr_gameno,sr_ctn,'Nuke',0,0);
        -- Get next territory
        Set sr_ctn=(Select terrname
                    From sp_board b
                         ,sp_places p
                    Where gameno=sr_gameno
                     and p.terrno=b.terrno
                     and userno not in (-9,-10)
                    Order by terrname desc
                    Limit 1
                    );
    END WHILE;
    -- Set message
    Insert Into sp_message_queue (gameno, userno, message, to_email)
    Values (sr_gameno, 0, "Nuclear Winter has descended.  Everyone is dead.", 0);
End If;

END sproc;
END
$$

Delimiter ;

/*
-- INSERT INTO `sp_powers` (`powername`, `terrtype`, `red`, `green`, `blue`) VALUES ('Neutron','NTRN',235,235,235);

-- delete from sp_old_orders;
-- delete from sp_message_queue;

-- Call sr_take_territory(48,'Greece','Nuke',0,0);
-- Call sr_take_territory(48,'British Isles','Nuke',0,0);
-- Call sr_take_territory(48,'Peru','Nuke',0,0);
-- Call sr_take_territory(48,'South Africa','Nuke',0,0);
-- Call sr_take_territory(48,'Brazil','Nuke',0,0);
-- Call sr_take_territory(48,'Eastern Australia','Nuke',0,0);
-- Call sr_take_territory(48,'Mid-west USA','Nuke',0,0);
-- Call sr_take_territory(48,'Venezuela','Nuke',0,0);
-- Call sr_take_territory(48,'Siberia','Nuke',0,0);
-- Call sr_take_territory(48,'India','Nuke',0,0);
-- Call sr_take_territory(48,'Java sea','Nuke',0,0);
-- Call sr_take_territory(48,'Indonesia','Nuke',0,0);
-- Call sr_take_territory(48,'Manchuria','Nuke',0,0);
-- Call sr_take_territory(48,'Zaire','Nuke',0,0);
-- Call sr_take_territory(48,'North Pacific','Nuke',0,0);
-- Call sr_is_it_winter(48);

-- select * from sp_old_orders;
-- select * from sp_message_queue;
*/