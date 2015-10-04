-- MySQL dump 10.13  Distrib 5.5.40, for Linux (x86_64)
--
-- Host: localhost    Database: asupcouk_asup
-- ------------------------------------------------------
-- Server version	5.5.40-cll

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
-- Table structure for table `sp_board`
--

DROP TABLE IF EXISTS `sp_board`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_board` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `terrno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) DEFAULT '0',
  `minor` int(11) DEFAULT '0',
  `major` int(11) DEFAULT '0',
  `defense` varchar(9) CHARACTER SET latin1 DEFAULT 'Defend',
  `attack_major` char(3) CHARACTER SET latin1 DEFAULT 'No',
  `passuser` int(11) DEFAULT '0',
  PRIMARY KEY (`gameno`,`terrno`),
  KEY `sp_board_game` (`gameno`),
  KEY `sp_board_place` (`terrno`),
  KEY `sp_board_user` (`userno`),
  CONSTRAINT `sp_board_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_board_place` FOREIGN KEY (`terrno`) REFERENCES `sp_places` (`terrno`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_boomers`
--

DROP TABLE IF EXISTS `sp_boomers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_boomers` (
  `gameno` int(11) NOT NULL,
  `userno` int(11) NOT NULL,
  `boomerno` int(11) NOT NULL,
  `terrno` int(11) NOT NULL,
  `visible` char(1) CHARACTER SET latin1 NOT NULL DEFAULT 'Y',
  `nukes` int(11) DEFAULT '0',
  `neutron` int(11) DEFAULT '0',
  PRIMARY KEY (`boomerno`,`gameno`,`userno`),
  KEY `fk_boomer_game_idx` (`gameno`),
  KEY `fk_boomer_resource_idx` (`gameno`,`userno`),
  KEY `fk_boomer_board_idx` (`gameno`,`terrno`),
  KEY `fk_boomer_place` (`terrno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_cards`
--

DROP TABLE IF EXISTS `sp_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_cards` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `cardno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) DEFAULT '0',
  `running` char(1) CHARACTER SET latin1 DEFAULT 'Y',
  `blocked` char(1) CHARACTER SET latin1 DEFAULT '',
  PRIMARY KEY (`gameno`,`cardno`),
  KEY `sp_cards_game` (`gameno`),
  KEY `sp_cards_user` (`userno`),
  KEY `sp_cards_card` (`cardno`),
  CONSTRAINT `sp_cards_card` FOREIGN KEY (`cardno`) REFERENCES `sp_res_cards` (`cardno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_cards_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_game`
--

DROP TABLE IF EXISTS `sp_game`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_game` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `turnno` int(11) DEFAULT '0',
  `phaseno` int(11) DEFAULT '0',
  `map_number` int(11) DEFAULT '0',
  `worldcup` int(11) DEFAULT '0',
  `process` int(11) DEFAULT NULL,
  `mapmod` int(11) DEFAULT '0',
  `nuke_tech_level` int(11) DEFAULT '1',
  `lstar_tech_level` int(11) DEFAULT '2',
  `ksat_tech_level` int(11) DEFAULT '3',
  `neutron_tech_level` int(11) DEFAULT '4',
  `blockade` char(1) CHARACTER SET latin1 DEFAULT 'N',
  `siege` char(1) CHARACTER SET latin1 DEFAULT 'N',
  `phase2_type` varchar(100) CHARACTER SET latin1 DEFAULT 'Choose 3',
  `boomers` char(1) CHARACTER SET latin1 DEFAULT 'Y',
  `liquid_asset_percent` int(11) DEFAULT '100',
  `company_restart_cost` int(11) DEFAULT '0',
  `beta` int(11) DEFAULT '0',
  `deadline_uts` int(11) DEFAULT NULL,
  `advance_uts` int(11) DEFAULT NULL,
  `winter_type` varchar(45) CHARACTER SET latin1 DEFAULT 'Nuclear & Neutron',
  `white_comms_level` int(11) DEFAULT '0',
  `grey_comms_level` int(11) DEFAULT '10',
  `black_comms_level` int(11) DEFAULT '10',
  `yellow_comms_level` int(11) NOT NULL DEFAULT '21',
  `auto_force` int(11) DEFAULT '604800',
  `tank_tech_level` int(11) DEFAULT '1',
  `boomer_tech_level` int(11) DEFAULT '1',
  `fortuna_flag` int(11) DEFAULT '1',
  PRIMARY KEY (`gameno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_lstars`
--

DROP TABLE IF EXISTS `sp_lstars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_lstars` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) NOT NULL DEFAULT '0',
  `lstarno` int(11) NOT NULL DEFAULT '0',
  `seqno` int(11) NOT NULL DEFAULT '0',
  `terrno` int(11) DEFAULT NULL,
  PRIMARY KEY (`gameno`,`userno`,`lstarno`,`seqno`),
  KEY `sp_lstars_game` (`gameno`),
  KEY `sp_lstars_user` (`userno`),
  KEY `sp_lstars_place` (`terrno`),
  CONSTRAINT `sp_lstars_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_lstars_user` FOREIGN KEY (`userno`) REFERENCES `sp_users` (`userno`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_market`
--

DROP TABLE IF EXISTS `sp_market`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_market` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `minerals_level` int(11) DEFAULT NULL,
  `oil_level` int(11) DEFAULT NULL,
  `grain_level` int(11) DEFAULT NULL,
  PRIMARY KEY (`gameno`),
  KEY `sp_market_game` (`gameno`),
  KEY `sp_market_oil` (`oil_level`),
  KEY `sp_market_minerals` (`minerals_level`),
  KEY `sp_market_grain` (`grain_level`),
  CONSTRAINT `sp_market_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_market_grain` FOREIGN KEY (`grain_level`) REFERENCES `sp_prices` (`market_level`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_market_minerals` FOREIGN KEY (`minerals_level`) REFERENCES `sp_prices` (`market_level`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_market_oil` FOREIGN KEY (`oil_level`) REFERENCES `sp_prices` (`market_level`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_message_queue`
--

DROP TABLE IF EXISTS `sp_message_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_message_queue` (
  `gameno` int(11) NOT NULL,
  `userno` int(11) NOT NULL,
  `message` text CHARACTER SET latin1 NOT NULL,
  `to_email` tinyint(1) NOT NULL DEFAULT '0',
  `messageno` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`messageno`),
  KEY `sp_message_queue_game` (`gameno`),
  CONSTRAINT `sp_message_queue_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2297 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_messages`
--

DROP TABLE IF EXISTS `sp_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_messages` (
  `gameno` int(11) DEFAULT NULL,
  `messageno` int(11) NOT NULL AUTO_INCREMENT,
  `userno` int(11) DEFAULT NULL,
  `message` text CHARACTER SET latin1,
  `message_uts` int(11) DEFAULT NULL,
  `to_email` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`messageno`),
  KEY `sp_message_user` (`userno`),
  KEY `sp_message_game_user` (`gameno`,`userno`)
) ENGINE=InnoDB AUTO_INCREMENT=1281301 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`asupcouk`@`%.virginm.net`*/ /*!50003 TRIGGER `asupcouk_asup`.`st_message_uts`
BEFORE INSERT ON `asupcouk_asup`.`sp_messages`
FOR EACH ROW
begin
set new.message_uts=case when new.message_uts is null Then unix_timestamp() Else new.message_uts End;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sp_old_orders`
--

DROP TABLE IF EXISTS `sp_old_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_old_orders` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) NOT NULL DEFAULT '0',
  `turnno` int(11) NOT NULL DEFAULT '0',
  `phaseno` int(11) NOT NULL DEFAULT '0',
  `ordername` varchar(32) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `order_code` text CHARACTER SET latin1,
  `order_uts` int(11) NOT NULL DEFAULT '0',
  `old_order_pk` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`old_order_pk`),
  KEY `sp_old_orders_game` (`gameno`)
) ENGINE=InnoDB AUTO_INCREMENT=38308133 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`asupcouk`@`%.virginm.net`*/ /*!50003 TRIGGER `asupcouk_asup`.`st_old_orders_uts`
BEFORE INSERT ON `asupcouk_asup`.`sp_old_orders`
FOR EACH ROW
begin
set new.order_uts=case when new.order_uts=0 Then unix_timestamp() else coalesce(new.order_uts,unix_timestamp()) end;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sp_orders`
--

DROP TABLE IF EXISTS `sp_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_orders` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) NOT NULL DEFAULT '0',
  `turnno` int(11) NOT NULL DEFAULT '0',
  `phaseno` int(11) NOT NULL DEFAULT '0',
  `ordername` varchar(20) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `order_code` text CHARACTER SET latin1,
  `orderno` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`orderno`),
  KEY `sp_orders_game` (`gameno`),
  KEY `sp_orders_user` (`userno`),
  CONSTRAINT `sp_orders_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=67726 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_resource`
--

DROP TABLE IF EXISTS `sp_resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_resource` (
  `gameno` int(11) NOT NULL DEFAULT '0',
  `powername` varchar(15) NOT NULL DEFAULT 'New',
  `userno` int(11) NOT NULL DEFAULT '0',
  `minerals` int(11) DEFAULT '3',
  `oil` int(11) DEFAULT '3',
  `grain` int(11) DEFAULT '3',
  `lstars` int(11) DEFAULT '0',
  `nukes` int(11) DEFAULT '0',
  `ksats` int(11) DEFAULT '0',
  `neutron` int(11) DEFAULT '0',
  `cash` int(11) DEFAULT '7000',
  `loan` int(11) DEFAULT '0',
  `max_oil` int(11) DEFAULT '12',
  `max_grain` int(11) DEFAULT '12',
  `max_minerals` int(11) DEFAULT '12',
  `land_tech` int(11) DEFAULT '0',
  `water_tech` int(11) DEFAULT '0',
  `strategic_tech` int(11) DEFAULT '0',
  `randgen` varchar(10) DEFAULT 'NONESETYET',
  `resource_tech` int(11) DEFAULT '0',
  `dead` char(1) DEFAULT 'N',
  `holiday` int(11) DEFAULT '20',
  `boomer_money` char(1) DEFAULT 'N',
  `interest` int(11) DEFAULT '0',
  `nukes_left` int(11) DEFAULT '12',
  `mia` int(11) DEFAULT '0',
  `espionage_tech` int(11) DEFAULT '0',
  `score` int(11) DEFAULT '0',
  `cash_transferred_in` int(11) DEFAULT '0',
  `cash_transferred_out` int(11) DEFAULT '0',
  `__utma` varchar(60) DEFAULT NULL,
  `naughty` char(1) DEFAULT 'N',
  `last_message_uts` int(11) DEFAULT '0',
  PRIMARY KEY (`gameno`,`powername`),
  KEY `sp_resource_game` (`gameno`),
  KEY `sp_resource_user` (`userno`),
  KEY `sp_resource_userno` (`gameno`,`userno`),
  KEY `sp_resource_powername` (`powername`),
  KEY `sp_resource_loan` (`loan`),
  KEY `sp_resource_land` (`land_tech`),
  KEY `sp_resource_water` (`water_tech`),
  CONSTRAINT `sp_resource_game` FOREIGN KEY (`gameno`) REFERENCES `sp_game` (`gameno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_resource_land` FOREIGN KEY (`land_tech`) REFERENCES `sp_tech` (`tech_level`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_resource_loan` FOREIGN KEY (`loan`) REFERENCES `sp_loan` (`loan_level`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_resource_powername` FOREIGN KEY (`powername`) REFERENCES `sp_powers` (`powername`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `sp_resource_user` FOREIGN KEY (`userno`) REFERENCES `sp_users` (`userno`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `sp_resource_water` FOREIGN KEY (`water_tech`) REFERENCES `sp_tech` (`tech_level`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40000 ALTER TABLE `sp_resource` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = latin1 */ ;
/*!50003 SET character_set_results = latin1 */ ;
/*!50003 SET collation_connection  = latin1_swedish_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`asupcouk`@`%.virginm.net`*/ /*!50003 trigger st_resource_bu
before update on sp_resource
for each row
begin

set new.max_minerals=greatest(least(new.max_minerals,36),0);
set new.max_oil=greatest(least(new.max_oil,36),0);
set new.max_grain=greatest(least(new.max_grain,36),0);

set new.land_tech=greatest(least(new.land_tech,5),0);
set new.water_tech=greatest(least(new.water_tech,5),0);
set new.strategic_tech=greatest(least(new.strategic_tech,5),0);
set new.resource_tech=greatest(least(new.resource_tech,5),0);
set new.espionage_tech=greatest(least(new.espionage_tech,20),-5);

set new.minerals=greatest(least(new.minerals, new.max_minerals),0);
set new.oil=greatest(least(new.oil, new.max_oil),0);
set new.grain=greatest(least(new.grain, new.max_grain),0);
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sp_newq`
--

DROP TABLE IF EXISTS `sp_newq`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_newq` (
  `userno` int(11) NOT NULL DEFAULT '0',
  `players` int(11) NOT NULL DEFAULT '6',
  `advance_uts` int(11) NOT NULL DEFAULT '86400',
  PRIMARY KEY (`players`,`advance_uts`,`userno`),
  KEY `sp_newq_user` (`userno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_newq_params`
--

DROP TABLE IF EXISTS `sp_newq_params`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_newq_params` (
  `players` int(11) NOT NULL DEFAULT '6',
  `advance_uts` int(11) NOT NULL DEFAULT '86400',
  `mapmod` int(11) DEFAULT '0',
  `nuke_tech_level` int(11) DEFAULT '2',
  `lstar_tech_level` int(11) DEFAULT '2',
  `ksat_tech_level` int(11) DEFAULT '3',
  `neutron_tech_level` int(11) DEFAULT '4',
  `blockade` char(1) CHARACTER SET latin1 DEFAULT 'Y',
  `siege` char(1) CHARACTER SET latin1 DEFAULT 'Y',
  `phase2_type` varchar(100) CHARACTER SET latin1 DEFAULT 'Choose 3',
  `boomers` char(1) CHARACTER SET latin1 DEFAULT 'Y',
  `liquid_asset_percent` int(11) DEFAULT '25',
  `company_restart_cost` int(11) DEFAULT '50',
  `winter_type` varchar(45) CHARACTER SET latin1 DEFAULT 'Nuclear & Neutron',
  `white_comms_level` int(11) DEFAULT '0',
  `grey_comms_level` int(11) DEFAULT '-4',
  `black_comms_level` int(11) DEFAULT '10',
  `yellow_comms_level` int(11) DEFAULT '21',
  `newq_description` varchar(256) CHARACTER SET latin1 DEFAULT NULL,
  `auto_force` int(11) DEFAULT '604800',
  `holiday` int(11) DEFAULT '14',
  `tank_tech_level` int(11) DEFAULT '1',
  `boomer_tech_level` int(11) DEFAULT '1',
  `fortuna_flag` int(11) DEFAULT '1',
  PRIMARY KEY (`players`,`advance_uts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-03-03 10:03:05
