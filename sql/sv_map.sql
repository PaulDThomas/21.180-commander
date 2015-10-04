-- View of the map, not including L-Star cover
-- $Id: sv_map.sql 242 2014-07-13 13:48:48Z paul $
use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop table if exists sv_map;
Drop view if exists sv_map;

create view sv_map as
select b.gameno AS gameno
       ,dr.x AS x
       ,dr.y AS y
       ,case
         when b.userno = -9 then 'Nuked'
         when b.userno = -10 then Concat('Neutron - ',Coalesce(r2.powername,'None'))
         when b.userno=-1 and length(pl.terrtype)=4 then 'Warlords'
         when b.userno=-1 and length(pl.terrtype)=3 then 'Pirates'
         when b.userno=0 then 'Locals'
         else r.powername
        end AS powername
       ,pl.terrtype AS terrtype
       ,pl.terrname AS terrname
       ,pw.red AS red
       ,pw.green AS green
       ,pw.blue AS blue
       ,b.terrno AS terrno
       ,b.userno AS userno
       ,dr.info AS info
       ,b.minor AS minor
       ,b.major AS major
       ,sum(case when rc.res_type = 'Minerals' and c.userno then rc.res_amount else 0 end) AS minerals
       ,sum(case when rc.res_type = 'Oil' and c.userno then rc.res_amount else 0 end) AS oil
       ,sum(case when rc.res_type = 'Grain' and c.userno then rc.res_amount else 0 end) AS grain
       ,Case When b.defense='Surren' Then 'Surrender' Else b.defense End AS defense
       ,b.attack_major AS attack_major
       ,b.passuser AS passuser
       ,Coalesce(r2.powername,'None') AS passusername
       ,Case
		 When pw.terrtype=pl.terrtype Then 'Home'
         Else ''
		End As home_territory
from asupcouk_asup.sp_board b
left join asupcouk_asup.sp_resource r on b.userno = r.userno and b.gameno = r.gameno
left join asupcouk_asup.sp_places pl on b.terrno = pl.terrno
left join asupcouk_asup.sp_drawing dr on dr.terrno = b.terrno
left join asupcouk_asup.sp_powers pw on pw.powername = (case when b.userno = -9 then 'Nuked' when b.userno = -10 then 'Neutron' when isnull(r.powername) then 'Neutral' else r.powername end)
left join asupcouk_asup.sp_res_cards rc on rc.terrno = b.terrno
left join asupcouk_asup.sp_cards c on c.cardno = rc.cardno and c.gameno = b.gameno and c.userno = b.userno and c.userno <> 0
left join asupcouk_asup.sp_resource r2 on r2.gameno=b.gameno and r2.userno=b.passuser and r2.dead='N'
group by b.gameno
 ,dr.x
 ,dr.y
 ,(case when b.userno = -9 then 'Nuked' when b.userno = -10 then 'Neutron' when isnull(r.powername) then 'Neutral' else r.powername end)
 ,pl.terrtype
 ,pl.terrname
 ,pw.red
 ,pw.green
 ,pw.blue
 ,b.terrno
 ,b.userno
 ,dr.info
 ,b.minor
 ,b.major
 ,b.defense
 ,b.attack_major
 ,b.passuser
 ,Coalesce(r2.powername,'None')
order by b.gameno
 ,b.terrno
;

-- select * from sv_map where gameno=154;