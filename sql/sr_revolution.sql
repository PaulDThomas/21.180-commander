use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_revolution;

DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_revolution` (sr_gameno INT, sr_powername TEXT, sr_userno INT)
BEGIN
sproc:BEGIN

-- Procedure to take over a Superpower
-- $Id: sr_revolution.sql 242 2014-07-13 13:48:48Z paul $
DECLARE proc_name TEXT DEFAULT "SR_REVOLUTION";
DECLARE sr_old_userno INT DEFAULT 0;
DECLARE sr_deadline_uts INT DEFAULT 0;

-- Check game and phase
IF sr_gameno not in (Select gameno From sp_game Where worldcup = 0 and (turnno <= Coalesce(@sr_revolution_override,3) or unix_timestamp()-deadline_uts >= 86400*14)) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                           Concat(sf_fxml("Reason","Invalid game or turn")
                                 ,sf_fxml("Gameno",sr_gameno)
                                 )
                           )
                   )
            );
    LEAVE sproc;
END IF;
Select deadline_uts Into sr_deadline_uts From sp_game Where gameno=sr_gameno;

-- Check Powername
IF sr_powername not in (Select powername From sp_resource Where gameno=sr_gameno and dead='N' and (mia >=3 or sr_deadline_uts <= unix_timestamp()-14*86400)) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Invalid Powername")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check User is valid
IF sr_userno not in (Select userno From sp_users) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Bad userno")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("Userno",sr_userno)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;

-- Check User not already in the game
IF sr_userno in (Select userno From sp_resource Where gameno=sr_gameno) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name
            ,Concat(sf_fxml("FAIL",
                            Concat(sf_fxml("Reason","Trying to get into a game twice")
                                  ,sf_fxml("Gameno",sr_gameno)
                                  ,sf_fxml("Powername",sr_powername)
                                  ,sf_fxml("Userno",sr_userno)
                                  )
                            )
                    )
            );
    LEAVE sproc;
END IF;
Select userno Into sr_old_userno From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- All ok, change the database
Update sp_messages Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_resource Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_board Set userno=sr_userno, defense='Defend',attack_major='No',passuser=0 Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_cards Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_orders Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_message_queue Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;
Update sp_lstars Set userno=sr_userno Where gameno=sr_gameno and userno=sr_old_userno;

-- Add message to old orders table
Insert into sp_old_orders (gameno, ordername, order_code)
 Values (sr_gameno, proc_name
        ,Concat(sf_fxml("SUCCESS",
                        Concat(sf_fxml("Gameno",sr_gameno)
                              ,sf_fxml("Powername",sr_powername)
                              ,sf_fxml("Userno",sr_userno)
                              ,sf_fxml("OldUserno",sr_old_userno)
                              )
                      )
                )
        );

-- Add message directly into message table
Insert Into sp_messages (gameno, userno, message)
 Values (sr_gameno, 0, Concat("Revolution in ",sf_format(sr_powername),"!!  New leader appointed."))
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

Update sp_resource Set mia=9 Where gameno=48 and powername='Arabia';

select userno, powername from sp_resource where gameno=48;

-- Check game
Call sr_revolution(-1,'Arabia',3475);

-- Check powername (dead)
Call sr_revolution(48,'Arabia',3475);

-- Check user (already in)
Call sr_revolution(48,'Canada',3227);

-- Check user (not real)
Call sr_revolution(48,'Canada',5);

-- Success
Call sr_revolution(192,'USA',3227);

select userno, powername from sp_resource where gameno=48;
*/
