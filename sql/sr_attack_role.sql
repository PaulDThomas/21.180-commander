use asupcouk_asup;
Drop procedure if exists sr_attack_role;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_attack_role` (sr_dice INT
                                           ,sr_mod INT
                                           ,sr_att_major CHAR(1)
                                           ,INOUT sr_land_major INT
                                           ,INOUT sr_land_minor INT
                                           ,INOUT sr_sea_major INT
                                           ,INOUT sr_sea_minor INT
                                           ,OUT roll_out INT
                                           )
BEGIN

-- Resolve an attack, require dice to roll, dice modifier, attack minor indicator
-- Return attacked land major/minor & sea major/minor
-- Should be called by sr_attack which will resolve input / output paramters around the game, power and territory names

sproc:BEGIN

-- $Id: sr_attack_role.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT Default "SR_ATTACK_ROLE";
DECLARE sr_roll INT Default 0;
DECLARE sr_dice_rolled INT Default 0;
DECLARE sr_land_major_hits INT Default 0;
DECLARE sr_land_minor_hits INT Default 0;
DECLARE sr_sea_major_hits INT Default 0;
DECLARE sr_sea_minor_hits INT Default 0;

-- Check something to do
IF sr_dice <= 0
   or (sr_land_major+sr_land_minor+sr_sea_major+sr_sea_minor) < 1
   or sr_land_major < 0
   or sr_land_minor < 0
   or sr_sea_major < 0
   or sr_sea_minor < 0

   or (sr_land_major >=1 and sr_sea_major >= 1)
   or (sr_sea_major >= 1 and sr_land_minor >= 1)

   or sr_land_major+sr_land_minor+sr_sea_major+sr_sea_minor
      +sr_dice+sr_mod is null

   or sr_dice > 5

   THEN
    Insert into sp_old_orders (ordername, order_code)
     Values (proc_name, Concat("<FAIL><Reason>Invalid Request</Reason>"
                              ,sf_fxml("Dice",sr_dice)
                              ,sf_fxml("Mod",sr_mod)
                              ,sf_fxml("LandMajor",sr_land_major)
                              ,sf_fxml("LandMinor",sr_land_minor)
                              ,sf_fxml("SeaMajor",sr_sea_major)
                              ,sf_fxml("SeaMinor",sr_sea_minor)
                              ,"</FAIL>")
            );
    Set sr_land_major = null;
    Set sr_land_minor = null;
    Set sr_sea_major = null;
    Set sr_sea_minor = null;
    Leave sproc;
End If;

-- Always ignore major if you only have one die or it is not specified
IF sr_dice = 1 or sr_att_major != 'Y' THEN
    Set sr_att_major='N';
END IF;

-- Roll the dice...
Set sr_roll = sr_mod;
WHILE sr_dice_rolled < sr_dice DO
BEGIN
   Set sr_roll = sr_roll + Ceil(Rand()*6);
   Set sr_dice_rolled = sr_dice_rolled + 1;
END;
END WHILE;

-- Make sure at least one point on the die
Set sr_roll = Greatest(sr_roll, sr_dice_rolled );
Set roll_out = sr_roll;

-- Delete Land majors if asked for
IF (sr_att_major = 'Y' and sr_roll >= 8 and sr_land_major > 0) THEN
    Set sr_land_major_hits = Least(sr_land_major,Floor(sr_roll/8));
    Set sr_land_major = sr_land_major-sr_land_major_hits;
    Set sr_roll = sr_roll - 8*sr_land_major_hits;
END IF;

-- Delete Sea majors if asked for
IF (sr_att_major = 'Y' and sr_roll >= 10 and sr_sea_major > 0) THEN
    Set sr_sea_major_hits = Least(sr_sea_major,Floor(sr_roll/10));
    Set sr_sea_major = sr_sea_major-sr_sea_major_hits;
    Set sr_roll = sr_roll - 10*sr_sea_major_hits;
END IF;

-- Remove Minors if not attacking majors, or a major has been hit
IF sr_att_major = 'N'
   or (sr_att_major = 'Y' and ((sr_land_major=0 and sr_sea_major=0)
                               or sr_land_major_hits >= 1
                               or sr_sea_major_hits >= 1
                               )
       )
   THEN
    -- Remove land forces first
    Set sr_land_minor_hits = Least(sr_land_minor,Floor(sr_roll/3));
    Set sr_land_minor = sr_land_minor-sr_land_minor_hits;
    Set sr_roll = sr_roll - 3*sr_land_minor_hits;
    -- Remove sea forces next
    Set sr_sea_minor_hits = Least(sr_sea_minor,Floor(sr_roll/3));
    Set sr_sea_minor = sr_sea_minor-sr_sea_minor_hits;
    Set sr_roll = sr_roll - 3*sr_sea_minor_hits;
END IF;

-- Remove majors if there is anything left
IF sr_roll >= 8 and sr_land_major > 0 THEN
    Set sr_land_major_hits = Least(sr_land_major,Floor(sr_roll/8));
    Set sr_land_major = sr_land_major-sr_land_major_hits;
    Set sr_roll = sr_roll - 8*sr_land_major_hits;
END IF;
IF sr_roll >= 10 and sr_sea_major > 0 THEN
    Set sr_sea_major_hits = Least(sr_sea_major,Floor(sr_roll/10));
    Set sr_sea_major = sr_sea_major-sr_sea_major_hits;
    Set sr_roll = sr_roll - 10*sr_sea_major_hits;
END IF;

-- Return results
IF @sr_debug!='N' THEN
    Select sr_land_major, sr_land_minor, sr_land_minor_hits, sr_sea_major, sr_sea_minor, sr_roll;
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;
/*
Delete from sp_message_queue;
Delete from sp_old_orders;

-- Just land minors
Set @lja=0; Set @lna=10; Set @sja=0; Set @sna=0;
-- call sr_attack_role (2, 0, 'N', @lja, @lna, @sja, @sna);

-- Just sea minors
Set @lja=0; Set @lna=0; Set @sja=0; Set @sna=10;
-- call sr_attack_role (2, 0, 'Y', @lja, @lna, @sja, @sna);

-- Amphibious with minors only
Set @lja=0; Set @lna=2; Set @sja=0; Set @sna=2;
-- call sr_attack_role (3, 0, 'Y', @lja, @lna, @sja, @sna);

-- Amphibious with tanks landing and being targetted
Set @lja=1; Set @lna=1; Set @sja=0; Set @sna=1;
-- call sr_attack_role (3, 0, 'Y', @lja, @lna, @sja, @sna);

-- Boomers
Set @lja=0; Set @lna=0; Set @sja=1; Set @sna=3;
-- call sr_attack_role (3, 1, 'N', @lja, @lna, @sja, @sna);
-- call sr_attack_role (3, 1, 'Y', @lja, @lna, @sja, @sna);

-- Tanks
Set @lja=5; Set @lna=5; Set @sja=0; Set @sna=0;
call sr_attack_role (2, 3, 'N', @lja, @lna, @sja, @sna);
call sr_attack_role (1, 0, 'Y', @lja, @lna, @sja, @sna);
call sr_attack_role (2, 3, 'Y', @lja, @lna, @sja, @sna);

-- select * from sp_message_queue;
-- select * from sv_map Where gameno=48 and terrname in ('Bay of Bengal','North Sea', 'Sea of Crete');
-- select * from sp_old_orders;
*/
