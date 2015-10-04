-- Trigger DDL Statements
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
DELIMITER $$

USE `asupcouk_asup`$$

Drop trigger if exists `asupcouk_asup`.`st_message_uts`$$

CREATE TRIGGER `asupcouk_asup`.`st_message_uts`
BEFORE INSERT ON `asupcouk_asup`.`sp_messages`
FOR EACH ROW
begin
set new.message_uts=case when new.message_uts is null Then unix_timestamp() Else new.message_uts End;
end$$

