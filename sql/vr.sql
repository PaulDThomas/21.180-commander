-- MySQL dump 10.13  Distrib 5.5.42, for Linux (x86_64)
--
-- Host: localhost    Database: asupcouk_asup
-- ------------------------------------------------------
-- Server version	5.5.42-cll

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Temporary table structure for view `sv_companies`
--

DROP TABLE IF EXISTS `sv_companies`;
/*!50001 DROP VIEW IF EXISTS `sv_companies`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_companies` (
  `gameno` tinyint NOT NULL,
  `userno` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `res_name` tinyint NOT NULL,
  `res_type` tinyint NOT NULL,
  `res_amount` tinyint NOT NULL,
  `cardno` tinyint NOT NULL,
  `trading` tinyint NOT NULL,
  `running` tinyint NOT NULL,
  `blocked` tinyint NOT NULL,
  `terrname` tinyint NOT NULL,
  `terrtype` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_current_orders`
--

DROP TABLE IF EXISTS `sv_current_orders`;
/*!50001 DROP VIEW IF EXISTS `sv_current_orders`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_current_orders` (
  `gameno` tinyint NOT NULL,
  `userno` tinyint NOT NULL,
  `username` tinyint NOT NULL,
  `naughty` tinyint NOT NULL,
  `mia` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `dead` tinyint NOT NULL,
  `turnno` tinyint NOT NULL,
  `phaseno` tinyint NOT NULL,
  `ordername` tinyint NOT NULL,
  `order_code` tinyint NOT NULL,
  `deadline_uts` tinyint NOT NULL,
  `advance_uts` tinyint NOT NULL,
  `deadline_gmt` tinyint NOT NULL,
  `advance` tinyint NOT NULL,
  `phasedesc` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_map`
--

DROP TABLE IF EXISTS `sv_map`;
/*!50001 DROP VIEW IF EXISTS `sv_map`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_map` (
  `gameno` tinyint NOT NULL,
  `x` tinyint NOT NULL,
  `y` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `terrtype` tinyint NOT NULL,
  `terrname` tinyint NOT NULL,
  `red` tinyint NOT NULL,
  `green` tinyint NOT NULL,
  `blue` tinyint NOT NULL,
  `terrno` tinyint NOT NULL,
  `userno` tinyint NOT NULL,
  `info` tinyint NOT NULL,
  `minor` tinyint NOT NULL,
  `major` tinyint NOT NULL,
  `minerals` tinyint NOT NULL,
  `oil` tinyint NOT NULL,
  `grain` tinyint NOT NULL,
  `defense` tinyint NOT NULL,
  `attack_major` tinyint NOT NULL,
  `passuser` tinyint NOT NULL,
  `passusername` tinyint NOT NULL,
  `home_territory` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_map_build`
--

DROP TABLE IF EXISTS `sv_map_build`;
/*!50001 DROP VIEW IF EXISTS `sv_map_build`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_map_build` (
  `gameno` tinyint NOT NULL,
  `terrno` tinyint NOT NULL,
  `terrname` tinyint NOT NULL,
  `terrtype` tinyint NOT NULL,
  `userno` tinyint NOT NULL,
  `major` tinyint NOT NULL,
  `minor` tinyint NOT NULL,
  `build_userno` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_market_prices`
--

DROP TABLE IF EXISTS `sv_market_prices`;
/*!50001 DROP VIEW IF EXISTS `sv_market_prices`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_market_prices` (
  `gameno` tinyint NOT NULL,
  `resource` tinyint NOT NULL,
  `price` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_next_powers`
--

DROP TABLE IF EXISTS `sv_next_powers`;
/*!50001 DROP VIEW IF EXISTS `sv_next_powers`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_next_powers` (
  `gameno` tinyint NOT NULL,
  `turnno` tinyint NOT NULL,
  `phaseno` tinyint NOT NULL,
  `current_powername` tinyint NOT NULL,
  `current_userno` tinyint NOT NULL,
  `waiting_powername` tinyint NOT NULL,
  `waiting_userno` tinyint NOT NULL,
  `redeploy` tinyint NOT NULL,
  `retaliation` tinyint NOT NULL,
  `extra` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_resources`
--

DROP TABLE IF EXISTS `sv_resources`;
/*!50001 DROP VIEW IF EXISTS `sv_resources`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_resources` (
  `gameno` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `userno` tinyint NOT NULL,
  `resource` tinyint NOT NULL,
  `resource_value` tinyint NOT NULL,
  `resource_max` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_siege`
--

DROP TABLE IF EXISTS `sv_siege`;
/*!50001 DROP VIEW IF EXISTS `sv_siege`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_siege` (
  `gameno` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `siege_status` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `sv_trading_partners`
--

DROP TABLE IF EXISTS `sv_trading_partners`;
/*!50001 DROP VIEW IF EXISTS `sv_trading_partners`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE TABLE `sv_trading_partners` (
  `gameno` tinyint NOT NULL,
  `powername` tinyint NOT NULL,
  `trading_partner` tinyint NOT NULL
) ENGINE=MyISAM */;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `sv_companies`
--

/*!50001 DROP TABLE IF EXISTS `sv_companies`*/;
/*!50001 DROP VIEW IF EXISTS `sv_companies`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_companies` AS select `b`.`gameno` AS `gameno`,`b`.`userno` AS `userno`,(case when (`r`.`powername` is not null) then `r`.`powername` when (`b`.`userno` = -(9)) then 'Nuked' when (`b`.`userno` = -(10)) then 'Neutron Waste' when (`b`.`userno` = -(1)) then 'Warlords' when (`b`.`userno` = 0) then 'Locals' else 'Unknown' end) AS `powername`,`rc`.`res_name` AS `res_name`,`rc`.`res_type` AS `res_type`,`rc`.`res_amount` AS `res_amount`,`c`.`cardno` AS `cardno`,(case when ((count(`b2`.`terrno`) > 0) or (`p1`.`terrtype` = `p`.`terrtype`)) then 'Trading' else 'Blockaded' end) AS `trading`,(case when (`c`.`running` = 'Y') then 'Running' else 'Closed' end) AS `running`,(case when (`c`.`blocked` = 'Y') then 'Trading' else 'Blockaded' end) AS `blocked`,`p1`.`terrname` AS `terrname`,`p1`.`terrtype` AS `terrtype` from ((((((((`sp_board` `b` join `sp_cards` `c` on(((`b`.`gameno` = `c`.`gameno`) and (`b`.`userno` = `c`.`userno`)))) join `sp_res_cards` `rc` on(((`c`.`cardno` = `rc`.`cardno`) and (`rc`.`terrno` = `b`.`terrno`)))) left join `sp_resource` `r` on(((`r`.`gameno` = `b`.`gameno`) and (`r`.`userno` = `b`.`userno`)))) left join `sp_powers` `p` on((`p`.`powername` = `r`.`powername`))) left join `sp_places` `p1` on((`p1`.`terrno` = `b`.`terrno`))) left join `sp_border` `bd` on((`b`.`terrno` = `bd`.`terrno_from`))) left join `sp_places` `p2` on((`p2`.`terrno` = `bd`.`terrno_to`))) left join `sp_board` `b2` on(((`p2`.`terrno` = `b2`.`terrno`) and (`b`.`gameno` = `b2`.`gameno`) and ((`b2`.`userno` in (0,`b`.`userno`)) or (`b`.`userno` = `b2`.`passuser`) or ((char_length(`p2`.`terrtype`) = 3) and (`b2`.`major` = 0) and (`b2`.`minor` = 0)))))) where ((char_length(`p2`.`terrtype`) <> char_length(`p1`.`terrtype`)) and (`c`.`userno` <> 0)) group by `b`.`gameno`,`b`.`userno`,`r`.`powername`,`b`.`terrno`,`p1`.`terrname`,`p`.`terrtype`,`p1`.`terrtype`,`c`.`cardno`,`c`.`running`,`rc`.`res_name`,`rc`.`res_type`,`rc`.`res_amount` order by 1,3,(case when (`rc`.`res_type` = 'Minerals') then 1 when (`rc`.`res_type` = 'Oil') then 2 else 3 end),`rc`.`res_amount` desc,`rc`.`res_name`,`b`.`terrno` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_current_orders`
--

/*!50001 DROP TABLE IF EXISTS `sv_current_orders`*/;
/*!50001 DROP VIEW IF EXISTS `sv_current_orders`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_current_orders` AS select `g`.`gameno` AS `gameno`,`u`.`userno` AS `userno`,`u`.`username` AS `username`,`r`.`naughty` AS `naughty`,`r`.`mia` AS `mia`,`r`.`powername` AS `powername`,`r`.`dead` AS `dead`,`g`.`turnno` AS `turnno`,`o`.`phaseno` AS `phaseno`,`o`.`ordername` AS `ordername`,`o`.`order_code` AS `order_code`,`g`.`deadline_uts` AS `deadline_uts`,`g`.`advance_uts` AS `advance_uts`,from_unixtime(`g`.`deadline_uts`) AS `deadline_gmt`,(case when (`g`.`advance_uts` < 60) then time_format(sec_to_time(`g`.`advance_uts`),'%ss') when (`g`.`advance_uts` < 3600) then time_format(sec_to_time(`g`.`advance_uts`),'%im') when ((`g`.`advance_uts` % 3600) = 0) then time_format(sec_to_time(`g`.`advance_uts`),'%kh') else time_format(sec_to_time(`g`.`advance_uts`),'%kh %im %ss') end) AS `advance`,(case `o`.`phaseno` when 0 then 'Setup' when 1 then 'Pay Salaries' when 2 then 'Phase Selection' when 3 then 'Sell' when 4 then 'Move and Attack' when 5 then 'Build and Research' when 6 then 'Buy' when 7 then 'Acquire Companies' else 'Game over' end) AS `phasedesc` from (((`sp_game` `g` left join `sp_resource` `r` on((`g`.`gameno` = `r`.`gameno`))) left join `sp_users` `u` on((`r`.`userno` = `u`.`userno`))) left join `sp_orders` `o` on(((`g`.`gameno` = `o`.`gameno`) and (`g`.`turnno` = `o`.`turnno`) and (`g`.`phaseno` <= `o`.`phaseno`) and (`o`.`userno` = `r`.`userno`)))) order by `g`.`gameno`,`g`.`turnno`,`o`.`phaseno`,`r`.`powername`,`o`.`ordername` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_map`
--

/*!50001 DROP TABLE IF EXISTS `sv_map`*/;
/*!50001 DROP VIEW IF EXISTS `sv_map`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_map` AS select `b`.`gameno` AS `gameno`,`dr`.`x` AS `x`,`dr`.`y` AS `y`,(case when (`b`.`userno` = -(9)) then 'Nuked' when (`b`.`userno` = -(10)) then concat('Neutron - ',coalesce(`r2`.`powername`,'None')) when ((`b`.`userno` = -(1)) and (length(`pl`.`terrtype`) = 4)) then 'Warlords' when ((`b`.`userno` = -(1)) and (length(`pl`.`terrtype`) = 3)) then 'Pirates' when (`b`.`userno` = 0) then 'Locals' else `r`.`powername` end) AS `powername`,`pl`.`terrtype` AS `terrtype`,`pl`.`terrname` AS `terrname`,`pw`.`red` AS `red`,`pw`.`green` AS `green`,`pw`.`blue` AS `blue`,`b`.`terrno` AS `terrno`,`b`.`userno` AS `userno`,`dr`.`info` AS `info`,`b`.`minor` AS `minor`,`b`.`major` AS `major`,sum((case when ((`rc`.`res_type` = 'Minerals') and `c`.`userno`) then `rc`.`res_amount` else 0 end)) AS `minerals`,sum((case when ((`rc`.`res_type` = 'Oil') and `c`.`userno`) then `rc`.`res_amount` else 0 end)) AS `oil`,sum((case when ((`rc`.`res_type` = 'Grain') and `c`.`userno`) then `rc`.`res_amount` else 0 end)) AS `grain`,(case when (`b`.`defense` = 'Surren') then 'Surrender' else `b`.`defense` end) AS `defense`,`b`.`attack_major` AS `attack_major`,`b`.`passuser` AS `passuser`,coalesce(`r2`.`powername`,'None') AS `passusername`,(case when (`pw`.`terrtype` = `pl`.`terrtype`) then 'Home' else '' end) AS `home_territory` from (((((((`sp_board` `b` left join `sp_resource` `r` on(((`b`.`userno` = `r`.`userno`) and (`b`.`gameno` = `r`.`gameno`)))) left join `sp_places` `pl` on((`b`.`terrno` = `pl`.`terrno`))) left join `sp_drawing` `dr` on((`dr`.`terrno` = `b`.`terrno`))) left join `sp_powers` `pw` on((`pw`.`powername` = (case when (`b`.`userno` = -(9)) then 'Nuked' when (`b`.`userno` = -(10)) then 'Neutron' when isnull(`r`.`powername`) then 'Neutral' else `r`.`powername` end)))) left join `sp_res_cards` `rc` on((`rc`.`terrno` = `b`.`terrno`))) left join `sp_cards` `c` on(((`c`.`cardno` = `rc`.`cardno`) and (`c`.`gameno` = `b`.`gameno`) and (`c`.`userno` = `b`.`userno`) and (`c`.`userno` <> 0)))) left join `sp_resource` `r2` on(((`r2`.`gameno` = `b`.`gameno`) and (`r2`.`userno` = `b`.`passuser`) and (`r2`.`dead` = 'N')))) group by `b`.`gameno`,`dr`.`x`,`dr`.`y`,(case when (`b`.`userno` = -(9)) then 'Nuked' when (`b`.`userno` = -(10)) then 'Neutron' when isnull(`r`.`powername`) then 'Neutral' else `r`.`powername` end),`pl`.`terrtype`,`pl`.`terrname`,`pw`.`red`,`pw`.`green`,`pw`.`blue`,`b`.`terrno`,`b`.`userno`,`dr`.`info`,`b`.`minor`,`b`.`major`,`b`.`defense`,`b`.`attack_major`,`b`.`passuser`,coalesce(`r2`.`powername`,'None') order by `b`.`gameno`,`b`.`terrno` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_map_build`
--

/*!50001 DROP TABLE IF EXISTS `sv_map_build`*/;
/*!50001 DROP VIEW IF EXISTS `sv_map_build`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_map_build` AS select `b`.`gameno` AS `gameno`,`b`.`terrno` AS `terrno`,`p`.`terrname` AS `terrname`,`p`.`terrtype` AS `terrtype`,`b`.`userno` AS `userno`,`b`.`major` AS `major`,`b`.`minor` AS `minor`,(case when (length(`p`.`terrtype`) = 4) then `b`.`userno` when ((`p`.`terrtype` = 'SEA') and (`b`.`userno` > 0) and (sum((`b2`.`userno` = `b`.`userno`)) > 0)) then `b`.`userno` when ((`p`.`terrtype` = 'SEA') and (`b`.`userno` = 0) and (count(distinct `b2`.`userno`) = 1)) then max(`b2`.`userno`) else 0 end) AS `build_userno` from ((((`sp_board` `b` join `sp_places` `p` on((`b`.`terrno` = `p`.`terrno`))) join `sp_border` `d` on((`b`.`terrno` = `d`.`terrno_from`))) left join `sp_places` `p2` on(((`d`.`terrno_to` = `p2`.`terrno`) and (length(`p`.`terrtype`) <> length(`p2`.`terrtype`))))) left join `sp_board` `b2` on(((`d`.`terrno_to` = `b2`.`terrno`) and (`b2`.`terrno` = `p2`.`terrno`) and (`b`.`gameno` = `b2`.`gameno`) and (`b2`.`userno` > 0)))) group by `b`.`gameno`,`b`.`terrno`,`p`.`terrname`,`p`.`terrtype`,`b`.`userno`,`b`.`major`,`b`.`minor` order by `b`.`gameno`,`p`.`terrname` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_market_prices`
--

/*!50001 DROP TABLE IF EXISTS `sv_market_prices`*/;
/*!50001 DROP VIEW IF EXISTS `sv_market_prices`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_market_prices` AS select `sp_market`.`gameno` AS `gameno`,'MINERALS' AS `resource`,`sp_prices`.`price` AS `price` from (`sp_market` left join `sp_prices` on((`sp_market`.`minerals_level` = `sp_prices`.`market_level`))) union select `sp_market`.`gameno` AS `gameno`,'OIL' AS `resource`,`sp_prices`.`price` AS `price` from (`sp_market` left join `sp_prices` on((`sp_market`.`oil_level` = `sp_prices`.`market_level`))) union select `sp_market`.`gameno` AS `gameno`,'GRAIN' AS `resource`,`sp_prices`.`price` AS `price` from (`sp_market` left join `sp_prices` on((`sp_market`.`grain_level` = `sp_prices`.`market_level`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_next_powers`
--

/*!50001 DROP TABLE IF EXISTS `sv_next_powers`*/;
/*!50001 DROP VIEW IF EXISTS `sv_next_powers`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_next_powers` AS select `o1`.`gameno` AS `gameno`,`o1`.`turnno` AS `turnno`,min(`o1`.`phaseno`) AS `phaseno`,`r1`.`powername` AS `current_powername`,`r1`.`userno` AS `current_userno`,coalesce(`r2`.`powername`,`r1`.`powername`) AS `waiting_powername`,coalesce(`r2`.`userno`,`r1`.`userno`) AS `waiting_userno`,coalesce((`o2`.`order_code` like '%deploy%'),0) AS `redeploy`,coalesce((`o2`.`order_code` like '%retaliation%'),0) AS `retaliation`,coalesce((`o2`.`order_code` like '%extra%'),0) AS `extra` from (((`sp_orders` `o1` left join `sp_resource` `r1` on(((`o1`.`gameno` = `r1`.`gameno`) and (`o1`.`userno` = `r1`.`userno`)))) left join `sp_orders` `o2` on(((`o1`.`gameno` = `o2`.`gameno`) and (`o1`.`turnno` = `o2`.`turnno`) and (`o1`.`phaseno` = `o2`.`phaseno`) and (`o2`.`ordername` = 'MA_000')))) left join `sp_resource` `r2` on(((`o2`.`gameno` = `r2`.`gameno`) and (`o2`.`userno` = `r2`.`userno`)))) where ((`o1`.`ordername` = 'ORDSTAT') and (`o1`.`order_code` in ('Waiting for orders','Orders processed','Orders processing'))) group by `o1`.`gameno`,`o1`.`turnno` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_resources`
--

/*!50001 DROP TABLE IF EXISTS `sv_resources`*/;
/*!50001 DROP VIEW IF EXISTS `sv_resources`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_resources` AS select `sp_resource`.`gameno` AS `gameno`,`sp_resource`.`powername` AS `powername`,`sp_resource`.`userno` AS `userno`,'MINERALS' AS `resource`,`sp_resource`.`minerals` AS `resource_value`,`sp_resource`.`max_minerals` AS `resource_max` from `sp_resource` union select `sp_resource`.`gameno` AS `gameno`,`sp_resource`.`powername` AS `powername`,`sp_resource`.`userno` AS `userno`,'OIL' AS `resource`,`sp_resource`.`oil` AS `resource_value`,`sp_resource`.`max_oil` AS `resource_max` from `sp_resource` union select `sp_resource`.`gameno` AS `gameno`,`sp_resource`.`powername` AS `powername`,`sp_resource`.`userno` AS `userno`,'GRAIN' AS `resource`,`sp_resource`.`grain` AS `resource_value`,`sp_resource`.`max_grain` AS `resource_max` from `sp_resource` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_siege`
--

/*!50001 DROP TABLE IF EXISTS `sv_siege`*/;
/*!50001 DROP VIEW IF EXISTS `sv_siege`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_siege` AS select `r1`.`gameno` AS `gameno`,`r1`.`powername` AS `powername`,(case when (count(`pl2`.`terrtype`) = 0) then 'Siege' else 'Trading' end) AS `siege_status` from ((((((`sp_resource` `r1` left join `sp_powers` `pw1` on((`r1`.`powername` = `pw1`.`powername`))) left join `sp_board` `b1` on(((`b1`.`gameno` = `r1`.`gameno`) and (`r1`.`userno` = `b1`.`userno`)))) left join `sp_places` `pl1` on(((`pl1`.`terrno` = `b1`.`terrno`) and (`pw1`.`terrtype` = `pl1`.`terrtype`)))) left join `sp_border` `br1` on((`pl1`.`terrno` = `br1`.`terrno_to`))) left join `sp_board` `b2` on(((`b2`.`terrno` = `br1`.`terrno_from`) and (`b2`.`gameno` = `r1`.`gameno`) and ((`b2`.`userno` in (0,`b1`.`userno`)) or (`b1`.`userno` = `b2`.`passuser`) or ((`b2`.`minor` = 0) and (`b2`.`major` = 0)))))) left join `sp_places` `pl2` on(((`pl2`.`terrno` = `b2`.`terrno`) and (length(`pl2`.`terrtype`) = 3)))) where (`r1`.`dead` = 'N') group by `r1`.`gameno`,`r1`.`powername` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `sv_trading_partners`
--

/*!50001 DROP TABLE IF EXISTS `sv_trading_partners`*/;
/*!50001 DROP VIEW IF EXISTS `sv_trading_partners`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`asupcouk`@`%.virginm.net` SQL SECURITY DEFINER */
/*!50001 VIEW `sv_trading_partners` AS select distinct `r1`.`gameno` AS `gameno`,`r1`.`powername` AS `powername`,(case when (`r3`.`userno` = `r1`.`userno`) then 'Market' else `r3`.`powername` end) AS `trading_partner` from (((((((((((((`sp_resource` `r1` join `sp_powers` `pw1` on((`r1`.`powername` = `pw1`.`powername`))) join `sp_board` `b1` on(((`b1`.`gameno` = `r1`.`gameno`) and (`r1`.`userno` = `b1`.`userno`)))) join `sp_places` `pl1` on(((`pl1`.`terrno` = `b1`.`terrno`) and (`pw1`.`terrtype` = `pl1`.`terrtype`)))) join `sp_border` `br1` on((`pl1`.`terrno` = `br1`.`terrno_to`))) join `sp_board` `b2` on(((`b2`.`terrno` = `br1`.`terrno_from`) and (`b2`.`gameno` = `r1`.`gameno`)))) join `sp_places` `pl2` on(((`pl2`.`terrno` = `b2`.`terrno`) and (`pl2`.`terrtype` = 'SEA')))) join `sp_resource` `r3` on((`r3`.`gameno` = `r1`.`gameno`))) join `sp_powers` `pw3` on((`r3`.`powername` = `pw3`.`powername`))) join `sp_board` `b3` on(((`b3`.`gameno` = `r1`.`gameno`) and (`r3`.`userno` = `b3`.`userno`)))) join `sp_places` `pl3` on(((`pl3`.`terrno` = `b3`.`terrno`) and (`pw3`.`terrtype` = `pl3`.`terrtype`)))) join `sp_border` `br3` on((`pl3`.`terrno` = `br3`.`terrno_to`))) join `sp_board` `b4` on(((`b4`.`terrno` = `br3`.`terrno_from`) and (`b4`.`gameno` = `r1`.`gameno`) and ((`b4`.`userno` in (0,`b3`.`userno`,`b1`.`userno`)) or (`b3`.`userno` = `b4`.`passuser`) or (`b4`.`minor` = 0))))) join `sp_places` `pl4` on(((`pl4`.`terrno` = `b4`.`terrno`) and (`pl4`.`terrtype` = 'SEA')))) where ((`r1`.`dead` = 'N') and (`r3`.`dead` = 'N') and ((`b2`.`userno` in (0,`b1`.`userno`,`b3`.`userno`)) or (`b1`.`userno` = `b2`.`passuser`) or ((`b2`.`major` = 0) and (`b2`.`minor` = 0)))) order by `r1`.`gameno`,`r1`.`powername`,(case when (`r3`.`userno` = `r1`.`userno`) then 'Market' else `r3`.`powername` end),(case when (`r3`.`userno` = `r1`.`userno`) then 0 else `r3`.`powername` end) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-08-04 10:03:20
