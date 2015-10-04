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
-- Table structure for table `sp__utma`
--

DROP TABLE IF EXISTS `sp__utma`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp__utma` (
  `idsp__utma` int(11) NOT NULL AUTO_INCREMENT,
  `userno` int(11) DEFAULT NULL,
  `__utma` varchar(60) CHARACTER SET latin1 DEFAULT NULL,
  `login_ip` varchar(10) CHARACTER SET latin1 DEFAULT NULL,
  `hostname` varchar(60) CHARACTER SET latin1 DEFAULT NULL,
  `login_uts` int(11) DEFAULT NULL,
  `user_agent` varchar(60) CHARACTER SET latin1 DEFAULT NULL,
  PRIMARY KEY (`idsp__utma`)
) ENGINE=InnoDB AUTO_INCREMENT=127373 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sp_news`
--

DROP TABLE IF EXISTS `sp_news`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_news` (
  `news` text CHARACTER SET latin1,
  `news_uts` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`news_uts`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sp_score`
--

DROP TABLE IF EXISTS `sp_score`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_score` (
  `xgameno` int(11) NOT NULL DEFAULT '0',
  `userno` int(11) NOT NULL DEFAULT '0',
  `score` int(11) DEFAULT '0',
  `finish_uts` int(11) DEFAULT '0',
  `players` int(11) DEFAULT '0',
  `alive_players` int(11) DEFAULT '0',
  `powername` varchar(15) CHARACTER SET latin1 DEFAULT NULL,
  PRIMARY KEY (`xgameno`,`userno`),
  KEY `sp_score_user` (`userno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


--
-- Table structure for table `sp_users`
--

DROP TABLE IF EXISTS `sp_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_users` (
  `userno` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(30) CHARACTER SET latin1 DEFAULT NULL,
  `pass` varchar(30) CHARACTER SET latin1 DEFAULT NULL,
  `email1` varchar(100) CHARACTER SET latin1 DEFAULT NULL,
  `email2` varchar(100) CHARACTER SET latin1 DEFAULT NULL,
  `promptness` int(11) DEFAULT '1',
  `ability` int(11) DEFAULT '1',
  `timezone` int(11) DEFAULT NULL,
  `map_type` char(3) CHARACTER SET latin1 DEFAULT 'PNG',
  `dt_format` varchar(30) CHARACTER SET latin1 DEFAULT 'jS F Y h:i:s a',
  `last_login_uts` int(11) DEFAULT NULL,
  `last_login_ip` varchar(16) CHARACTER SET latin1 DEFAULT '0.0.0.0',
  `last_hostname` varchar(60) CHARACTER SET latin1 DEFAULT NULL,
  `admin` varchar(1) CHARACTER SET latin1 DEFAULT 'N',
  PRIMARY KEY (`userno`)
) ENGINE=InnoDB AUTO_INCREMENT=3957 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sp_worldcup`
--

DROP TABLE IF EXISTS `sp_worldcup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sp_worldcup` (
  `userno` int(11) NOT NULL DEFAULT '0',
  `first_name` varchar(30) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `last_name` varchar(30) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `country` varchar(30) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `region` varchar(30) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `ip` varchar(20) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `remote_addr` varchar(40) CHARACTER SET latin1 NOT NULL DEFAULT '',
  PRIMARY KEY (`userno`),
  KEY `sp_world_cup_user` (`userno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-08-04 10:03:19
