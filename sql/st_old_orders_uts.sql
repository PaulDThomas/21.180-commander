-- Full Trigger DDL Statements
-- Note: Only CREATE TRIGGER statements are allowed
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
DELIMITER $$

USE `asupcouk_asup`$$
DROP TRIGGER IF EXISTS asupcouk_asup.st_old_orders_uts$$

CREATE
TRIGGER `asupcouk_asup`.`st_old_orders_uts`
BEFORE INSERT ON `asupcouk_asup`.`sp_old_orders`
FOR EACH ROW
begin
set new.order_uts=case when new.order_uts=0 Then unix_timestamp() else coalesce(new.order_uts,unix_timestamp()) end;
end$$
