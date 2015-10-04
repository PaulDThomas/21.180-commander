-- View for who can build where
-- $Id: sv_map_build.sql 242 2014-07-13 13:48:48Z paul $
use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
Drop Table If Exists sv_map_build;
Drop View If Exists sv_map_build;

/*
Create
View sv_map_build As
Select b.gameno, b.terrno, p.terrname, p.terrtype, b.userno, b.major, b.minor
,Case
   When Length(p.terrtype)=4 Then b.userno
   When p.terrtype='SEA' and Count(Distinct b2.userno)=1 Then Max(b2.userno)
   When p.terrtype='OCE' Then 0
   Else b.userno
  End As build_userno
From sp_board b
Inner Join sp_places p On b.terrno = p.terrno
Inner Join sp_border d On b.terrno = d.terrno_from
Left Join sp_places p2 On d.terrno_to = p2.terrno and Length(p.terrtype) != Length(p2.terrtype)
Left Join sp_board b2 On d.terrno_to = b2.terrno and b2.terrno=p2.terrno and b.gameno = b2.gameno and b.userno = 0 and b2.userno > 0
Group by b.gameno, b.terrno, p.terrname, p.terrtype, b.userno, b.major, b.minor
Order By b.gameno
 ,p.terrname
;
*/

CREATE
VIEW sv_map_build AS
Select b.gameno    As gameno
       ,b.terrno   As terrno
       ,p.terrname As terrname
       ,p.terrtype As terrtype
       ,b.userno   As userno
       ,b.major    As major
       ,b.minor    As minor
       ,Case
            When Length(p.terrtype) = 4 Then b.userno
            When p.terrtype = 'SEA' and b.userno > 0 and Sum((b2.userno=b.userno))>0 Then b.userno
            When p.terrtype = 'SEA' and b.userno = 0 and Count(Distinct b2.userno)=1 Then Max(b2.userno)
            Else 0
          end As build_userno
From   sp_board b
Join   sp_places p
 On    b.terrno = p.terrno
Join   sp_border d
 On    b.terrno = d.terrno_from
Left Join sp_places p2
 On    d.terrno_to = p2.terrno
       And Length(p.terrtype) <> Length(p2.terrtype)
Left Join sp_board b2
 On    d.terrno_to = b2.terrno
       And b2.terrno = p2.terrno
       And b.gameno = b2.gameno
       And b2.userno > 0
Group  By b.gameno
          ,b.terrno
          ,p.terrname
          ,p.terrtype
          ,b.userno
          ,b.major
          ,b.minor
Order  By b.gameno
          ,p.terrname
;

-- call sr_take_territory(49,'Shark Bay','Neutral',0,0);
-- call sr_take_territory(49,'Tasman Sea','Neutral',0,0);

-- select * from sv_map_build where gameno=105;

