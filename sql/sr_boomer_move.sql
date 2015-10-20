use asupcouk_asup;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
DROP PROCEDURE IF EXISTS `asupcouk_asup`.`sr_boomer_move`;

DELIMITER $$

CREATE PROCEDURE `asupcouk_asup`.`sr_boomer_move` (sr_gameno INT
											      ,sr_powername TEXT
                                                  ,sr_boomerno INT
												  ,sr_terrname_to TEXT
												  ,sr_visible CHAR(1)
												  ,sr_nukes INT
												  ,sr_neutron INT
											      )
BEGIN
sproc: BEGIN

--
-- Routine to move a boomer outside phase 4
--
-- $Id: sr_boomer_move.sql 309 2015-10-20 22:27:23Z paul $
DECLARE proc_name TEXT Default "SR_BOOMER_MOVE";
DECLARE sr_turnno INT Default 0;
DECLARE sr_phaseno INT Default 0;
DECLARE sr_userno INT Default 0;
DECLARE sr_nukes_available INT Default 0;
DECLARE sr_neutron_available INT Default 0;
DECLARE sr_nukes_avafter INT Default 0;
DECLARE sr_neutron_avafter INT Default 0;
DECLARE sr_terrname_from TEXT;
DECLARE sr_terrno_from INT Default 0;
DECLARE sr_nukes_before INT Default 0;
DECLARE sr_neutron_before INT Default 0;
DECLARE sr_home_terrno INT Default 0;
DECLARE sr_home_terrname TEXT;
DECLARE sr_is_visible CHAR(1);
DECLARE sr_terrno_to INT Default 0;
DECLARE sr_major_from_before INT Default 0;
DECLARE sr_minor_from_before INT Default 0;
DECLARE sr_major_to_before INT Default 0;
DECLARE sr_minor_to_before INT Default 0;

-- Check game
IF sr_gameno not in (Select gameno From sp_game Where phaseno < 9) THEN
    Insert into sp_old_orders (gameno, ordername, order_code)
     Values (sr_gameno, proc_name, Concat("<FAIL><Reason>Invalid Game</Reason>"
                                         ,sf_fxml("Gameno",sr_gameno)
                                         ,"</FAIL>")
            );
    LEAVE sproc;
END IF;
Select turnno, phaseno Into sr_turnno, sr_phaseno From sp_game Where gameno=sr_gameno;

-- Ensure not Move/Attack phase
IF sr_phaseno=4 THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Can never move in phase 4</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;

-- Check powername
IF Upper(sr_powername) not in (Select Upper(powername) From sp_resource r Where gameno=sr_gameno and dead='N') THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Invalid Power</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;
Select userno, nukes, neutron Into sr_userno, sr_nukes_available, sr_neutron_available From sp_resource Where gameno=sr_gameno and powername=sr_powername;

-- Check boomer number
IF sr_boomerno not in (Select boomerno
					   From   sp_boomers b
					   Where  b.gameno=sr_gameno
						and   b.userno=sr_userno
					   ) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Invalid Boomer number</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;
Select bm.terrno, nukes, neutron, visible, Max(b.terrno), Max(pl.terrname)
Into sr_terrno_from, sr_nukes_before, sr_neutron_before, sr_is_visible, sr_home_terrno, sr_home_terrname
From sp_boomers bm
Left Join sp_border br On bm.terrno=br.terrno_from
Left Join sp_powers pw On pw.powername=sr_powername
Left Join sp_places pl On br.terrno_to=pl.terrno and pl.terrtype=pw.terrtype
Left Join sp_board b On b.gameno=bm.gameno and b.terrno=pl.terrno and b.userno=sr_userno
Where bm.gameno=sr_gameno
 and bm.userno=sr_userno
 and bm.boomerno=sr_boomerno
Limit 1
;
Select terrname Into sr_terrname_from From sp_places Where terrno=sr_terrno_from;

-- Check warheads are not going down
IF sr_nukes < sr_nukes_before or sr_neutron < sr_neutron_before THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Missing warheads</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
					  ,sf_fxml("Nukes",sr_nukes)
					  ,sf_fxml("NeutronBombs",sr_neutron)
					  ,sf_fxml("NukesBefore",sr_nukes_before)
					  ,sf_fxml("NeutronBefore",sr_neutron_before)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;

-- Check there is a port to load from
IF (sr_nukes > sr_nukes_before and (sr_is_visible='N' or sr_home_terrno is null))
   or (sr_neutron > sr_neutron_before and (sr_is_visible='N' or sr_home_terrno is null)) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Loading when not in port</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
					  ,sf_fxml("Nukes",sr_nukes)
					  ,sf_fxml("NeutronBombs",sr_neutron)
					  ,sf_fxml("NukesBefore",sr_nukes_before)
					  ,sf_fxml("NeutronBefore",sr_neutron_before)
                      ,sf_fxml("NukesAvailable",sr_nukes_available)
					  ,sf_fxml("NeutronAvailable",sr_neutron_available)
					  ,sf_fxml("CurrentTerrno",sr_terrno_from)
					  ,sf_fxml("PortTerrno",sr_home_terrno)
					  ,sf_fxml("IsVisible",sr_is_visible)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;

-- Check number of nukes
IF (sr_nukes > 2)
   or (sr_nukes > sr_nukes_before+sr_nukes_available)
   or (sr_neutron > 2)
   or (sr_neutron > sr_neutron_before+sr_neutron_available)
   or (sr_nukes+sr_neutron > 2) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Too many warheads being loaded</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
					  ,sf_fxml("Nukes",sr_nukes)
					  ,sf_fxml("NeutronBombs",sr_neutron)
					  ,sf_fxml("NukesBefore",sr_nukes_before)
					  ,sf_fxml("NeutronBefore",sr_neutron_before)
                      ,sf_fxml("NukesAvailable",sr_nukes_available)
					  ,sf_fxml("NeutronAvailable",sr_neutron_available)
					  ,sf_fxml("CurrentTerrno",sr_terrno_from)
					  ,sf_fxml("PortTerrno",sr_home_terrno)
					  ,sf_fxml("IsVisible",sr_is_visible)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;

-- Check terrname to
IF sr_terrname_to not in (Select terrname
                          From   sp_board b
                          Left Join sp_places p
                          On     b.terrno=p.terrno
                          Where  b.userno > -9
						   and Length(p.terrtype)=3
                           and Case When sr_visible='Y' Then userno=sr_userno Else 1 End
                          ) THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>Invalid to territory</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
					  ,sf_fxml("TerrnameTo",sr_terrname_to)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;
Select terrno Into sr_terrno_to From sp_places Where terrname=sr_terrname_to;
Select major, minor Into sr_major_from_before, sr_minor_from_before From sp_board Where gameno=sr_gameno and terrno=sr_terrno_from;
Select major, minor Into sr_major_to_before, sr_minor_to_before From sp_board Where gameno=sr_gameno and terrno=sr_terrno_to;

-- Check some movement
/*
IF sr_terrno_to=sr_terrno_from and sr_is_visible=sr_visible THEN
    Insert Into sp_old_orders (gameno, userno, turnno, phaseno, ordername, order_code)
        Values (sr_gameno, sr_userno, sr_turnno, sr_phaseno, proc_name
               ,Concat("<FAIL><Reason>No movement</Reason>"
                      ,sf_fxml("Gameno",sr_gameno)
                      ,sf_fxml("Powername",sr_powername)
                      ,sf_fxml("BoomerNumber",sr_boomerno)
					  ,sf_fxml("TerrnameTo",sr_terrname_to)
					  ,sf_fxml("TerrnameFrom",sr_terrname_from)
					  ,sf_fxml("IsVisible",sr_is_visible)
					  ,sf_fxml("Visible",sr_visible)
                      ,"</FAIL>")
               );
    LEAVE sproc;
END IF;
*/

-- Force hidden if not visible
IF sr_visible not in ('Y') THEN Set sr_visible='N'; END IF;

IF @sr_debug != 'N' THEN
	Select sr_terrno_from, sr_terrno_to, sr_home_terrname, sr_visible, sr_major_from_before, sr_minor_from_before, sr_major_to_before, sr_minor_to_before;
END IF;

-- Make update
Update sp_boomers
Set terrno=sr_terrno_to, visible=sr_visible, nukes=sr_nukes, neutron=sr_neutron
Where gameno=sr_gameno
 and userno=sr_userno
 and boomerno=sr_boomerno
;
-- Update territory from
IF sr_is_visible='Y' and (sr_is_visible!=sr_visible or sr_terrno_from!=sr_terrno_to) THEN
	Call sr_take_territory(sr_gameno, sr_terrname_from, sr_powername, sr_major_from_before-1, sr_minor_from_before);
END IF;
-- Update territory to
IF sr_visible='Y' and (sr_is_visible!=sr_visible or sr_terrno_from!=sr_terrno_to) THEN
	Call sr_take_territory(sr_gameno, sr_terrname_to, sr_powername, sr_major_to_before+1, sr_minor_to_before);
END IF;
-- Update resource card
IF sr_nukes > sr_nukes_before or sr_neutron > sr_neutron_before THEN
	Set sr_nukes_avafter=sr_nukes_available-sr_nukes+sr_nukes_before
     ,sr_neutron_avafter=sr_neutron_available-sr_neutron+sr_neutron_before
     ;
	Update sp_resource
	Set nukes=sr_nukes_avafter
     ,neutron=sr_neutron_avafter
    Where gameno=sr_gameno
     and powername=sr_powername
    ;
END IF;

-- Set old orders success
Insert into sp_old_orders (gameno, ordername, order_code, turnno, phaseno)
 Values (sr_gameno, proc_name, Concat("<SUCCESS>"
                                     ,sf_fxml("Gameno",sr_gameno)
                                     ,sf_fxml("Powername",sr_powername)
									 ,sf_fxml("BoomerNumber",sr_boomerno)
                                     ,sf_fxml("TerrnameTo",sr_terrname_to)
                                     ,sf_fxml("TerrnoTo",sr_terrno_to)
									 ,sf_fxml("Visible",sr_visible)
									 ,sf_fxml("Nukes",sr_nukes)
									 ,sf_fxml("NeutronBombs",sr_neutron)
									 ,sf_fxml("NukesBefore",sr_nukes_before)
									 ,sf_fxml("NeutronBefore",sr_neutron_before)
									 ,sf_fxml("NukesAvailable",sr_nukes_available)
									 ,sf_fxml("NeutronAvailable",sr_neutron_available)
									 ,sf_fxml("NukesAvailableAfter",sr_nukes_avafter)
									 ,sf_fxml("NeutronAvailableAfter",sr_neutron_avafter)
									 ,sf_fxml("CurrentTerrno",sr_terrno_from)
									 ,sf_fxml("CurrentTerrname",sr_terrname_from)
									 ,sf_fxml("MajorFromBefore",sr_major_from_before)
									 ,sf_fxml("MinorFromBefore",sr_minor_from_before)
									 ,sf_fxml("MajorToBefore",sr_major_from_before)
									 ,sf_fxml("MinorToBefore",sr_minor_from_before)
									 ,sf_fxml("PortTerrno",sr_home_terrno)
									 ,sf_fxml("PortTerritory",sr_home_terrname)
									 ,sf_fxml("IsVisible",sr_is_visible)
                                     ,"</SUCCESS>")
        ,sr_turnno, sr_phaseno);

-- User message
IF sr_visible!=sr_is_visible or sr_terrno_from!=sr_terrno_to or sr_nukes>sr_nukes_before or sr_neutron>sr_neutron_before THEN
	Insert Into sp_messages (gameno, userno, message)
	 Values (sr_gameno, sr_userno
			,Concat("You have moved your boomer from "
					,sr_terrname_from
					," to "
					,sr_terrname_to
					,". Where is it now "
					,Case When sr_visible='Y' Then 'visible' Else 'hidden' End
					,'. It is carrying '
					,Case When sr_nukes=2 Then '2 nukes' When sr_nukes=1 Then '1 nuke' Else '' End
					,Case When sr_nukes>0 and sr_neutron>0 Then ' and ' Else '' End
					,Case When sr_neutron=2 Then '2 neutron bombs' When sr_neutron=1 Then '1 neutron bomb' Else '' End
					,Case When sr_neutron=0 and sr_nukes=0 Then 'no warheads' Else '' End
					,'.'
					,Case When sr_nukes>sr_nukes_before or sr_neutron>sr_neutron_before Then
						  Concat('  Extra warheads were loaded from '
								,sr_home_terrname
								,'. You have '
								,Case When sr_nukes_avafter>1 Then Concat(sr_nukes_avafter,' nukes') When sr_nukes_avafter=1 Then '1 nuke' Else '' End
								,Case When sr_nukes_avafter>0 and sr_neutron_avafter>0 Then ' and ' Else '' End
								,Case When sr_neutron_avafter>1 Then Concat(sr_neutron_avafter,' neutron bombs') When sr_neutron=1 Then '1 neutron bomb' Else '' End
								,Case When sr_neutron=0 and sr_nukes=0 Then 'no warheads' Else '' End
								,' available now.'
								)
						  Else '' End
						)
			);
END IF;

-- /* */
END sproc;
END
$$

Delimiter ;