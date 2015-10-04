-- View for what orders are in place
-- $Id: sv_current_orders.sql 242 2014-07-13 13:48:48Z paul $
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
use asupcouk_asup;
drop table if exists sv_current_orders;
drop table if exists sv_next_powers;
drop view if exists sv_current_orders;
drop view if exists sv_next_powers;

create
view sv_next_powers as
Select o1.gameno, o1.turnno, min(o1.phaseno) as phaseno
 ,r1.powername as current_powername
 ,r1.userno as current_userno
 ,Coalesce(r2.powername, r1.powername) As waiting_powername
 ,Coalesce(r2.userno, r1.userno) As waiting_userno
 ,Coalesce(o2.order_code like '%deploy%',0) As redeploy
 ,Coalesce(o2.order_code like '%retaliation%',0) as retaliation
 ,Coalesce(o2.order_code like '%extra%',0) as extra
From sp_orders o1
Left Join sp_resource r1 on o1.gameno=r1.gameno and o1.userno=r1.userno
Left Join sp_orders o2 On o1.gameno=o2.gameno and o1.turnno=o2.turnno and o1.phaseno=o2.phaseno and o2.ordername='MA_000'
Left Join sp_resource r2 on o2.gameno=r2.gameno and o2.userno=r2.userno
Where o1.ordername='ORDSTAT'
 and o1.order_code in ('Waiting for orders','Orders processed','Orders processing')
Group By o1.gameno, o1.turnno
;

create
view sv_current_orders as
select g.gameno
 ,u.userno
 ,username
 ,naughty
 ,mia
 ,powername
 ,dead
 ,g.turnno
 ,o.phaseno
 ,ordername
 ,order_code
 ,deadline_uts
 ,advance_uts
 ,from_unixtime(deadline_uts) as deadline_gmt
 ,Case
   When g.advance_uts < 60 Then TIME_FORMAT(SEC_TO_TIME(g.advance_uts),'%ss')
   When g.advance_uts < 3600 Then TIME_FORMAT(SEC_TO_TIME(g.advance_uts),'%im')
   When g.advance_uts%3600=0 Then TIME_FORMAT(SEC_TO_TIME(g.advance_uts),'%kh')
   Else TIME_FORMAT(SEC_TO_TIME(g.advance_uts),'%kh %im %ss')
  End as advance
 ,Case o.phaseno
   When 0 Then "Setup"
   When 1 Then "Pay Salaries"
   When 2 Then "Phase Selection"
   When 3 Then "Sell"
   When 4 Then "Move and Attack"
   When 5 Then "Build and Research"
   When 6 Then "Buy"
   When 7 Then "Acquire Companies"
   Else "Game over"
  End as phasedesc
from sp_game g
left Join sp_resource r on g.gameno=r.gameno
left join sp_users u on r.userno=u.userno
left join sp_orders o on g.gameno=o.gameno and g.turnno=o.turnno and g.phaseno <= o.phaseno and o.userno=r.userno
order by g.gameno, g.turnno, o.phaseno, r.powername, o.ordername
;
