use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop procedure if exists sr_take_resource;

DELIMITER $$

CREATE
PROCEDURE `asupcouk_asup`.`sr_take_resource` (sr_gameno INT, sr_from_userno INT, sr_to_userno INT, sr_resource TEXT, sr_mod DOUBLE, INOUT sr_messagexml TEXT)
BEGIN
sproc:BEGIN

-- Procedure to move resource from one Superpower to another on death
-- Called from sr_check_alive
-- Assumes validation is not required!!!
-- $Id: sr_take_resource.sql 242 2014-07-13 13:48:48Z paul $

-- Get value of resource
Set @sql_ret = Concat("Select Floor(",sr_resource,"*",sr_mod,") Into @val From sp_resource Where gameno=",sr_gameno," and userno=",sr_from_userno);
Prepare sql_ret From @sql_ret;
Execute sql_ret;
Deallocate Prepare sql_ret;

-- Return value
Select Concat(sr_messagexml,sf_format_xml(sr_resource, sf_format(sr_resource), @val)) Into sr_messagexml;

Set @sql_upd = Concat("Update sp_resource Set ",sr_resource
                     ," = ",sr_resource," + ",@val
                     ," Where gameno = ",sr_gameno
                     ," and userno = ",sr_to_userno
                     );
Prepare sql_upd From @sql_upd;
Execute sql_upd;
Deallocate Prepare sql_upd;

/* Can not do this until all resources have been taken!
Set @sql_upd = Concat("Update sp_resource Set ",sr_resource
                     ," = ",sr_resource," - ",@val
                     ," Where gameno = ",sr_gameno
                     ," and userno = ",sr_from_userno
                     );
Prepare sql_upd From @sql_upd;
Execute sql_upd;
Deallocate Prepare sql_upd;

-- /* */
END sproc;
END;

$$

Delimiter ;

/*
update sp_resource set minerals=5 where gameno=48 and userno in (3227,3238);
select userno, powername, minerals from sp_resource where gameno=48 and userno in (3227,3238);

Set @message='';
Call sr_take_resource(48,3227,3238,'minerals',0.5,@message);
Select @message;

select userno, powername, minerals from sp_resource where gameno=48 and userno in (3227,3238);
*/