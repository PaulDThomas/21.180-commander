-- View for who is what what companies, and if they are blockaded or not
-- $Id: sv_companies.sql 247 2014-07-16 20:40:38Z paul $
use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
drop view if exists sv_companies;

create
view sv_companies as
Select b.gameno
       ,b.userno
       ,Case
         When r.powername is not null then r.powername
         When b.userno=-9 then 'Nuked'
         When b.userno=-10 then 'Neutron Waste'
         When b.userno=-1 then 'Warlords'
         When b.userno=0 then 'Locals'
         Else 'Unknown'
        End as powername
       ,rc.res_name
       ,rc.res_type
       ,rc.res_amount
       ,c.cardno
       ,Case
         When count(b2.terrno)>0 or p1.terrtype=p.terrtype Then 'Trading'
         Else 'Blockaded'
        End As trading
       ,Case When c.running='Y' Then 'Running' Else 'Closed' End as running
       ,Case When c.blocked='Y' Then 'Trading' Else 'Blockaded' End as blocked
       ,p1.terrname
       ,p1.terrtype
From sp_board b
Inner Join sp_cards c On b.gameno=c.gameno
                         and b.userno=c.userno
Inner Join sp_res_cards rc On c.cardno=rc.cardno
                              and rc.terrno=b.terrno
Left Join sp_resource r On r.gameno=b.gameno
                           and r.userno=b.userno
Left Join sp_powers p On p.powername=r.powername
Left Join sp_places p1 On p1.terrno=b.terrno
Left Join sp_border bd On b.terrno=bd.terrno_from
Left Join sp_places p2 On p2.terrno=bd.terrno_to
Left Join sp_board b2 On p2.terrno=b2.terrno
                         and b.gameno=b2.gameno
                         and (b2.userno in (0,b.userno) or b.userno=b2.passuser or (char_length(p2.terrtype)=3 and b2.major=0 and b2.minor=0))
Where char_length(p2.terrtype)!=char_length(p1.terrtype) and c.userno != 0
Group By b.gameno
       ,b.userno
       ,r.powername
       ,b.terrno
       ,p1.terrname
       ,p.terrtype
       ,p1.terrtype
       ,c.cardno
       ,c.running
       ,rc.res_name
       ,rc.res_type
       ,rc.res_amount
Order by 1, 3
       ,Case
         When rc.res_type='Minerals' Then 1
         When rc.res_type='Oil' Then 2
         Else 3
        End
       ,rc.res_amount desc
       ,rc.res_name
       ,b.terrno
;