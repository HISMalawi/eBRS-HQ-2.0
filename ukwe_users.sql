-- MySQL dump 10.13  Distrib 5.5.62, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: ebrs_hq_v2
-- ------------------------------------------------------
-- Server version	5.5.62-0ubuntu0.14.04.1

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
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `location_id` int(11) DEFAULT NULL,
  `username` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `plain_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator` bigint(20) NOT NULL DEFAULT '0',
  `person_id` bigint(20) DEFAULT NULL,
  `active` tinyint(4) NOT NULL DEFAULT '1',
  `un_or_block_reason` varchar(225) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(225) COLLATE utf8_unicode_ci DEFAULT NULL,
  `notify` tinyint(4) NOT NULL DEFAULT '0',
  `preferred_keyboard` varchar(10) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'abc',
  `password_attempt` bigint(20) DEFAULT '0',
  `last_password_date` datetime DEFAULT NULL,
  `uuid` varchar(38) COLLATE utf8_unicode_ci DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `fk_users_1_idx` (`person_id`) USING BTREE,
  KEY `fk_users_2_idx` (`voided_by`) USING BTREE,
  CONSTRAINT `fk_users_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_users_2` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100279182 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--
-- WHERE:   person_id LIKE '35076%' 

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-08-02 12:08:31
