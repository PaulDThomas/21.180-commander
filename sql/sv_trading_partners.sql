-- View for who is under Siege
-- $Id: sv_trading_partners.sql 252 2014-08-24 21:18:23Z paul $
use asupcouk_asup;
Drop Table If Exists sv_trading_partners;
Drop View If Exists sv_trading_partners;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

Create View sv_trading_partners As
Select Distinct r1.gameno, r1.powername
 ,Case When r3.userno=r1.userno Then 'Market' Else r3.powername End as trading_partner
-- ,pl1.terrname, pl2.terrname as sea, b1.userno as landuserno, b2.userno as seauserno
-- ,pl4.terrname as osea, b4.userno as oseaunserno, b3.userno as olanduserno, pl3.terrname as oland
From sp_resource r1
-- Get powername
 Join sp_powers pw1 On r1.powername=pw1.powername
-- Get board details for Land 1
 Join sp_board b1 On b1.gameno=r1.gameno and r1.userno=b1.userno
-- Get place information for Land 1
 Join sp_places pl1 On pl1.terrno=b1.terrno and pw1.terrtype=pl1.terrtype
-- Find connecting Sea 2
 Join sp_border br1 On pl1.terrno=br1.terrno_to
-- Get board details for Sea 2, ensure it can be entered
 Join sp_board b2 On b2.terrno=br1.terrno_from and b2.gameno=r1.gameno /*and (b2.userno in (0,b1.userno) or b1.userno=b2.passuser or b2.minor=0)*/
-- Get place information for Sea 2
 Join sp_places pl2 On pl2.terrno=b2.terrno and pl2.terrtype='SEA'


-- Get second power
 Join sp_resource r3 On r3.gameno=r1.gameno
-- Get second powername
 Join sp_powers pw3 On r3.powername=pw3.powername
-- Get board details for Land 3
 Join sp_board b3 On b3.gameno=r1.gameno and r3.userno=b3.userno
-- Get place information for Land 3
 Join sp_places pl3 On pl3.terrno=b3.terrno and pw3.terrtype=pl3.terrtype
-- Find connecting sea 4
 Join sp_border br3 On pl3.terrno=br3.terrno_to
-- Ensure connecting sea can be entered by first power or left by second power
 Join sp_board b4 On b4.terrno=br3.terrno_from and b4.gameno=r1.gameno and (b4.userno in (0,b3.userno,b1.userno) or b3.userno=b4.passuser or b4.minor=0)
-- Get place information for sea 4
 Join sp_places pl4 On pl4.terrno=b4.terrno and pl4.terrtype='SEA'

Where r1.dead='N'
 and r3.dead='N'
 and (b2.userno in (0,b1.userno,b3.userno) or b1.userno=b2.passuser or (b2.major=0 and b2.minor=0))

Order By r1.gameno, r1.powername, trading_partner
 ,Case When r3.userno=r1.userno Then 0 Else r3.powername End
;

select *
from sv_trading_partners
where gameno=221
 and powername='Africa'
;
-- /* */