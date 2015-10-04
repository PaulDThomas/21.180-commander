-- $Id: sf_format.sql 242 2014-07-13 13:48:48Z paul $
Use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

Drop function if exists sf_format;
Drop function if exists sf_format_hms;

Create Function sf_format(in_text TEXT) Returns text Deterministic
Return Case Upper(in_text)
When 'MAX_MINERALS' Then 'Minerals Storage'
When 'MAX_OIL' Then 'Oil Storage'
When 'MAX_GRAIN' Then 'Grain Storage'
When 'SOUTH AMERICA' Then 'South America'
When 'NORTH AMERICA' Then 'North America'
When 'LSTARS' Then 'L-Stars'
When 'KSATS' Then 'K-Sats'
When 'LAND_TECH' Then 'Armies Technology'
When 'WATER_TECH' Then 'Navies Technology'
When 'RESOURCE_TECH' Then 'Resource Technology'
When 'ESPIONAGE_TECH' Then 'Espionage Technology'
When 'STRATEGIC_TECH' Then 'Strategic Technology'
When 'NUKES_LEFT' Then 'Uranium Reserves'
When 'LOAN' Then 'Loan taken'
When 'NUKES' Then 'Nuclear Weapons'
When 'CASH' Then 'Cash'
When 'EURO' Then 'Europe'
When 'AFRI' Then 'Africa'
When 'RUSS' Then 'USSR'
When 'USSR' Then 'USSR'
When 'AUST' Then 'Australia'
When 'ARAB' Then 'Arabia'
When 'S_AM' Then 'South America'
When 'N_AM' Then 'USA'
When 'USA' Then 'USA'
When 'CANA' Then 'Canada'
When 'CHIN' Then 'China'
When 'NEUT' Then 'Neutral'
When 'SEA' Then 'Sea'
When 'OCE' Then 'Ocean'
Else Concat(Upper(Substring(in_text,1,1)),Lower(Substring(in_text from 2)))
End;

-- Select sf_format('ksats'), sf_format('N_AM'), sf_format('OIL');
-- Select distinct sf_format(terrtype) From sp_places;

Create Function sf_format_hms(in_sec INT) Returns text Deterministic
Return
Case
 When (in_sec < 60) then time_format(sec_to_time(in_sec),'%ss')
 When (in_sec < 3600) then time_format(sec_to_time(in_sec),'%im')
 When in_sec%3600 = 0 then time_format(sec_to_time(in_sec),'%kh')
 Else time_format(sec_to_time(in_sec),'%kh %im %ss')
 End;

-- Select sf_format_hms(86400), sf_format_hms(5), sf_format_hms(3600), sf_format_hms(46023);