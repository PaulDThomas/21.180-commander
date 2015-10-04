-- View for who is under Siege
-- $Id: sv_siege.sql 268 2014-12-02 07:31:43Z paul $
use asupcouk_asup;
Drop table if exists sv_siege;
Drop view if exists sv_siege;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;

create
view sv_siege as
Select r1.gameno, r1.powername, Case When Count(pl2.terrtype)=0 Then 'Siege' Else 'Trading' End As siege_status
From sp_resource r1
Left Join sp_powers pw1 On r1.powername=pw1.powername
Left Join sp_board b1 On b1.gameno=r1.gameno and r1.userno=b1.userno
Left Join sp_places pl1 On pl1.terrno=b1.terrno and pw1.terrtype=pl1.terrtype
Left Join sp_border br1 On pl1.terrno=br1.terrno_to
Left Join sp_board b2 On b2.terrno=br1.terrno_from and b2.gameno=r1.gameno and (b2.userno in (0,b1.userno) or b1.userno=b2.passuser or (b2.minor=0 and b2.major=0))
Left Join sp_places pl2 On pl2.terrno=b2.terrno and length(pl2.terrtype)=3
Where r1.dead='N'
Group By r1.gameno, r1.powername
;
/*
select * from sv_siege where gameno=48;
*/
