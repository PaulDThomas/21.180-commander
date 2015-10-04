-- Hash for a map to check for reloading image
-- $Id: sv_map_hash.sql 242 2014-07-13 13:48:48Z paul $
Use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
DROP VIEW IF EXISTS sv_map_hash;
CREATE VIEW sv_map_hash As
Select g.gameno
 ,g.turnno
 ,g.phaseno
 ,Sum(b.terrno*b.userno*(10*major+Least(minor,9)+7))
  +Coalesce(Sum(l.terrno*l.userno),0)
  +10000*Coalesce(Sum(bm.terrno*bm.userno),0)
  +Sum(c.cardno*c.userno) as mapHash
 ,g.deadline_uts
 ,g.beta
 ,g.worldcup
From sp_game g
Left Join sp_board b On b.gameno=g.gameno
Left Join sp_lstars l On b.gameno=l.gameno and b.terrno=l.terrno
Left Join sp_boomers bm On b.gameno=bm.gameno and b.terrno=bm.terrno and visible != 'Y'
Left Join sp_cards c On c.gameno=g.gameno
Group By g.gameno
;
-- Select * From sv_map_hash Order By mapHash
;