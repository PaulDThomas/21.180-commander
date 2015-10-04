/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Use asupcouk_asup;

Drop function if exists sf_format_xml;

-- $Id: sf_format_xml.sql 242 2014-07-13 13:48:48Z paul $

Create Function sf_format_xml(in_param TEXT,in_label TEXT,in_value TEXT) Returns text Deterministic
Return Concat("<",in_param,Case When Length(in_label)>1 Then Concat(" Label='",in_label,"'>")
                                Else ">" End
             ,Coalesce(REPLACE(in_value, '&', '&amp;'),'Null')
             ,"</",in_param,">"
             );

-- Select sf_format_xml('ksats','Attacking K-Sats',3);
-- Select sf_format_xml('ksats','',3);

Drop function if exists sf_fxml;

Create Function sf_fxml(in_param TEXT,in_value TEXT) Returns text Deterministic
Return Concat("<",in_param,">",Coalesce(REPLACE(in_value, '&', '&amp;'),'Null'),"</",in_param,">");

-- Select sf_fxml('ksats',"Large &<>'"" lager");
-- Select sf_fxml('ksats',null);
