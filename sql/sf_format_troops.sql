use asupcouk_asup;
Drop function if exists sf_format_troops;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

-- --------------------------------------------------------------------------------
-- Routine DDL
-- Note: comments before and after the routine body will not be stored by the server
-- --------------------------------------------------------------------------------
DELIMITER $$

CREATE FUNCTION `asupcouk_asup`.`sf_format_troops` (sr_type CHAR(4), sr_major INT, sr_minor INT) Returns text Deterministic
BEGIN
Set @minor=Case
           When Length(sr_type)=3 and sr_minor=1 Then '1 Navy'
           When Length(sr_type)=3 and sr_minor>1 Then Concat(sr_minor,' Navies')
           When Length(sr_type)=4 and sr_minor=1 Then '1 Army'
           When Length(sr_type)=4 and sr_minor>1 Then Concat(sr_minor,' Armies')
           Else ''
           End;
Set @major=Case
           When Length(sr_type)=3 and sr_major=1 Then '1 Boomer'
           When Length(sr_type)=3 and sr_major>1 Then Concat(sr_major,' Boomers')
           When Length(sr_type)=4 and sr_major=1 Then '1 Tank'
           When Length(sr_type)=4 and sr_major>1 Then Concat(sr_major,' Tanks')
           Else ''
           End;
Return Case When @minor != '' and @major != '' Then Concat(@minor,' and ',@major)
            When @minor != '' Then @minor
            When @major != '' Then @major
            Else '0 troops'
            End;
END;
$$
DELIMITER ;

/*
Select
sf_format_troops('SEA',1,1)
,sf_format_troops('OCE',0,0)
,sf_format_troops('SEA',2,2)
,sf_format_troops('SEA',1,0)
,sf_format_troops('SEA',0,2)
,sf_format_troops('NEUT',1,2)
,sf_format_troops('CANA',1,2)
,sf_format_troops('N_AM',2,0)
,sf_format_troops('RUSS',0,1)
;
*/