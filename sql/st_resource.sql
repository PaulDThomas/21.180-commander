use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

drop trigger if exists st_resource_bu;

delimiter $$

create
trigger st_resource_bu
before update on sp_resource
for each row
begin
-- Set maximum resource card to 24
set new.max_minerals=greatest(least(new.max_minerals,36),0);
set new.max_oil=greatest(least(new.max_oil,36),0);
set new.max_grain=greatest(least(new.max_grain,36),0);
-- Set max and min for techs
set new.land_tech=greatest(least(new.land_tech,5),0);
set new.water_tech=greatest(least(new.water_tech,5),0);
set new.strategic_tech=greatest(least(new.strategic_tech,5),0);
set new.resource_tech=greatest(least(new.resource_tech,5),0);
set new.espionage_tech=greatest(least(new.espionage_tech,20),-5);
-- Ensure that resources do not exceed max amounts
set new.minerals=greatest(least(new.minerals, new.max_minerals),0);
set new.oil=greatest(least(new.oil, new.max_oil),0);
set new.grain=greatest(least(new.grain, new.max_grain),0);
end;
$$
Delimiter ;
