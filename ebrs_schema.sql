-- MySQL dump 10.13  Distrib 5.5.62, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: ebrs2_hq
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
-- Table structure for table `audit_trail_types`
--

DROP TABLE IF EXISTS `audit_trail_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_trail_types` (
  `audit_trail_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`audit_trail_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_trails`
--

DROP TABLE IF EXISTS `audit_trails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_trails` (
  `audit_trail_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `audit_trail_type_id` int(11) NOT NULL,
  `person_id` bigint(20) NOT NULL,
  `table_name` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `table_row_id` bigint(20) DEFAULT NULL,
  `field` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `previous_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `current_value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comment` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `location_id` int(11) NOT NULL,
  `ip_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mac_address` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`audit_trail_id`),
  KEY `fk_audit_trails_1` (`audit_trail_type_id`) USING BTREE,
  KEY `fk_audit_trails_3` (`creator`) USING BTREE,
  KEY `fk_audit_trails_2` (`location_id`) USING BTREE,
  KEY `fk_audit_trails_4` (`person_id`) USING BTREE,
  CONSTRAINT `fk_audit_trails_1` FOREIGN KEY (`audit_trail_type_id`) REFERENCES `audit_trail_types` (`audit_trail_type_id`),
  CONSTRAINT `fk_audit_trails_2` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_audit_trails_3` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `fk_audit_trails_4` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10026025308 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barcode_identifiers`
--

DROP TABLE IF EXISTS `barcode_identifiers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `barcode_identifiers` (
  `barcode_identifier_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `value` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `assigned` tinyint(4) NOT NULL DEFAULT '0',
  `person_id` bigint(20) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`barcode_identifier_id`),
  UNIQUE KEY `value_UNIQUE` (`value`) USING BTREE,
  KEY `fk_barcode_identifiers_1` (`person_id`),
  CONSTRAINT `fk_barcode_identifiers_1` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100279110000 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `birth_registration_type`
--

DROP TABLE IF EXISTS `birth_registration_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `birth_registration_type` (
  `birth_registration_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`birth_registration_type_id`),
  UNIQUE KEY `birth_registration_type_id_UNIQUE` (`birth_registration_type_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `brn_counter`
--

DROP TABLE IF EXISTS `brn_counter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `brn_counter` (
  `counter` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`counter`),
  UNIQUE KEY `counter_UNIQUE` (`counter`),
  UNIQUE KEY `pid_UNIQUE` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1483878 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `certificate`
--

DROP TABLE IF EXISTS `certificate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `certificate` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `date_printed` datetime DEFAULT NULL,
  `date_dispatched` datetime DEFAULT NULL,
  `print_count` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=399584 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `core_person`
--

DROP TABLE IF EXISTS `core_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `core_person` (
  `person_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_type_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_id`),
  UNIQUE KEY `person_id_UNIQUE` (`person_id`) USING BTREE,
  KEY `fk_core_person_1_idx` (`person_type_id`) USING BTREE,
  KEY `idx_core_person_id` (`person_id`),
  CONSTRAINT `fk_core_person_1` FOREIGN KEY (`person_type_id`) REFERENCES `person_type` (`person_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=135077196553 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `couchdb_sequence`
--

DROP TABLE IF EXISTS `couchdb_sequence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `couchdb_sequence` (
  `couchdb_sequence_id` int(11) NOT NULL AUTO_INCREMENT,
  `seq` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`couchdb_sequence_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `duplicate_records`
--

DROP TABLE IF EXISTS `duplicate_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `duplicate_records` (
  `duplicate_record_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) DEFAULT NULL,
  `potential_duplicate_id` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`duplicate_record_id`),
  KEY `fk_duplicate_records_1` (`potential_duplicate_id`),
  KEY `fk_duplicate_records_2` (`person_id`),
  CONSTRAINT `fk_duplicate_records_1` FOREIGN KEY (`potential_duplicate_id`) REFERENCES `potential_duplicates` (`potential_duplicate_id`),
  CONSTRAINT `fk_duplicate_records_2` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10026816609 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ebrs_migration`
--

DROP TABLE IF EXISTS `ebrs_migration`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ebrs_migration` (
  `ebrs_migration_id` int(11) NOT NULL AUTO_INCREMENT,
  `page_size` bigint(20) DEFAULT NULL,
  `current_page` bigint(20) DEFAULT NULL,
  `file_number` int(11) DEFAULT NULL,
  PRIMARY KEY (`ebrs_migration_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `error_records`
--

DROP TABLE IF EXISTS `error_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `error_records` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `passed` smallint(6) NOT NULL,
  `table_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=677338 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `global_property`
--

DROP TABLE IF EXISTS `global_property`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `global_property` (
  `global_property_id` int(11) NOT NULL AUTO_INCREMENT,
  `property` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `value` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `uuid` varchar(38) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`global_property_id`),
  KEY `fk_global_property_1_idx` (`property`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `identifier_allocation_queue`
--

DROP TABLE IF EXISTS `identifier_allocation_queue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `identifier_allocation_queue` (
  `identifier_allocation_queue_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `person_identifier_type_id` int(11) NOT NULL,
  `assigned` tinyint(4) NOT NULL DEFAULT '0',
  `creator` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`identifier_allocation_queue_id`),
  KEY `fk_identifier_allocation_queue_1_idx` (`person_id`) USING BTREE,
  KEY `fk_identifier_allocation_queue_2` (`person_identifier_type_id`) USING BTREE,
  CONSTRAINT `fk_identifier_allocation_queue_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_identifier_allocation_queue_2` FOREIGN KEY (`person_identifier_type_id`) REFERENCES `person_identifier_types` (`person_identifier_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1162601 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `level_of_education`
--

DROP TABLE IF EXISTS `level_of_education`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `level_of_education` (
  `level_of_education_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  PRIMARY KEY (`level_of_education_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location`
--

DROP TABLE IF EXISTS `location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location` (
  `location_id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postal_code` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `latitude` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `longitude` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `creator` bigint(20) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `county_district` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_location` int(11) DEFAULT NULL,
  `uuid` varchar(38) COLLATE utf8_unicode_ci NOT NULL,
  `changed_by` bigint(20) DEFAULT NULL,
  `changed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`location_id`),
  UNIQUE KEY `location_uuid_index` (`uuid`) USING BTREE,
  KEY `location_changed_by` (`changed_by`) USING BTREE,
  KEY `user_who_created_location` (`creator`) USING BTREE,
  KEY `name_of_location` (`name`) USING BTREE,
  KEY `parent_location` (`parent_location`) USING BTREE,
  KEY `retired_status` (`voided`) USING BTREE,
  KEY `user_who_retired_location` (`voided_by`) USING BTREE,
  KEY `idx_location_id` (`location_id`)
) ENGINE=InnoDB AUTO_INCREMENT=36550 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location_tag`
--

DROP TABLE IF EXISTS `location_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_tag` (
  `location_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `voided_by` bigint(20) DEFAULT NULL,
  `void_reason` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`location_tag_id`),
  UNIQUE KEY `location_tag_map_id_UNIQUE` (`location_tag_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `location_tag_map`
--

DROP TABLE IF EXISTS `location_tag_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_tag_map` (
  `location_id` int(11) NOT NULL,
  `location_tag_id` int(11) NOT NULL,
  KEY `fk_location_tag_map_1` (`location_id`) USING BTREE,
  KEY `fk_location_tag_map_2_idx` (`location_tag_id`) USING BTREE,
  KEY `idx_location_tag_map_id` (`location_tag_id`),
  KEY `idx_location_tag_loc_id` (`location_id`),
  CONSTRAINT `fk_location_tag_map_1` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_location_tag_map_2` FOREIGN KEY (`location_tag_id`) REFERENCES `location_tag` (`location_tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mass_data`
--

DROP TABLE IF EXISTS `mass_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mass_data` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `Surname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `OtherNames` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FirstName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `DateOfBirthString` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Sex` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Nationality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Nationality2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `TypeOfDelivery` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ModeOfDelivery` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `LevelOfEducation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherPin` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherSurname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherMaidenName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherFirstName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherOtherNames` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherNationality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherPin` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherSurname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherFirstName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherOtherNames` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherVillageId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherNationality` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `EbrsPk` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `NrisPk` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PlaceOfBirthDistrictId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PlaceOfBirthDistrictName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PlaceOfBirthTAName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PlaceOfBirthVillageName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `PlaceOfBirthVillageId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherDistrictId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherDistrictName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherTAName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherVillageName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherVillageId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherDistrictId` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherDistrictName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherTAName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherVillageName` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `EditUser` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `EditMachine` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `BirthCertificateNumber` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `DistrictOfRegistration` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MotherAge` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FatherAge` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `DateRegistered` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Category` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `load_status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=233281 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mode_of_delivery`
--

DROP TABLE IF EXISTS `mode_of_delivery`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mode_of_delivery` (
  `mode_of_delivery_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  PRIMARY KEY (`mode_of_delivery_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nid_verification_data`
--

DROP TABLE IF EXISTS `nid_verification_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nid_verification_data` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `passed` smallint(6) NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3277 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification` (
  `notification_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `notification_type_id` int(11) NOT NULL,
  `person_record_status_id` bigint(20) NOT NULL,
  `person_id` bigint(20) DEFAULT NULL,
  `seen` tinyint(4) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`notification_id`),
  KEY `fk_notification_1` (`notification_type_id`),
  KEY `fk_notification_2` (`person_record_status_id`),
  KEY `fk_notification_3` (`person_id`),
  CONSTRAINT `fk_notification_1` FOREIGN KEY (`notification_type_id`) REFERENCES `notification_types` (`notification_type_id`),
  CONSTRAINT `fk_notification_2` FOREIGN KEY (`person_record_status_id`) REFERENCES `person_record_statuses` (`person_record_status_id`),
  CONSTRAINT `fk_notification_3` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100279462333 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notification_types`
--

DROP TABLE IF EXISTS `notification_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `notification_types` (
  `notification_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `level` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `trigger_status_id` int(11) DEFAULT NULL,
  `role_id` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`notification_type_id`),
  KEY `fk_notification_types_1` (`trigger_status_id`),
  CONSTRAINT `fk_notification_types_1` FOREIGN KEY (`trigger_status_id`) REFERENCES `statuses` (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person`
--

DROP TABLE IF EXISTS `person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person` (
  `person_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `gender` varchar(6) COLLATE utf8_unicode_ci NOT NULL,
  `birthdate_estimated` tinyint(4) NOT NULL DEFAULT '0',
  `birthdate` date NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_id`),
  CONSTRAINT `fk_person_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=135077196527 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_addresses`
--

DROP TABLE IF EXISTS `person_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_addresses` (
  `person_addresses_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `current_village` int(11) DEFAULT NULL,
  `current_village_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `current_ta` int(11) DEFAULT NULL,
  `current_ta_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `current_district` int(11) DEFAULT NULL,
  `current_district_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `home_village` int(11) DEFAULT NULL,
  `home_village_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `home_ta` int(11) DEFAULT NULL,
  `home_ta_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `home_district` int(11) DEFAULT NULL,
  `home_district_other` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `citizenship` int(11) NOT NULL,
  `residential_country` int(11) NOT NULL,
  `address_line_1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address_line_2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_addresses_id`),
  KEY `fk_person_addresses_8_idx` (`citizenship`) USING BTREE,
  KEY `fk_person_addresses_4_idx` (`current_district`) USING BTREE,
  KEY `fk_person_addresses_3_idx` (`current_ta`) USING BTREE,
  KEY `fk_person_addresses_2_idx` (`current_village`,`current_ta`,`current_district`,`home_village`,`home_ta`,`home_district`) USING BTREE,
  KEY `fk_person_addresses_7_idx` (`home_district`) USING BTREE,
  KEY `fk_person_addresses_6_idx` (`home_ta`) USING BTREE,
  KEY `fk_person_addresses_5_idx` (`home_village`) USING BTREE,
  KEY `fk_person_addresses_1_idx` (`person_id`) USING BTREE,
  CONSTRAINT `fk_person_addresses_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_addresses_2` FOREIGN KEY (`current_village`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_addresses_3` FOREIGN KEY (`current_ta`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_addresses_4` FOREIGN KEY (`current_district`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_addresses_5` FOREIGN KEY (`home_village`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_addresses_6` FOREIGN KEY (`home_ta`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_addresses_7` FOREIGN KEY (`home_district`) REFERENCES `location` (`location_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100277113338 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_attribute_types`
--

DROP TABLE IF EXISTS `person_attribute_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_attribute_types` (
  `person_attribute_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_attribute_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_attributes`
--

DROP TABLE IF EXISTS `person_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_attributes` (
  `person_attribute_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `person_attribute_type_id` int(11) NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `value` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_attribute_id`),
  KEY `fk_person_attributes_2_idx` (`person_attribute_type_id`) USING BTREE,
  KEY `fk_person_attributes_1_idx` (`person_id`) USING BTREE,
  CONSTRAINT `fk_person_attributes_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_attributes_2` FOREIGN KEY (`person_attribute_type_id`) REFERENCES `person_attribute_types` (`person_attribute_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100271415557 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_birth_details`
--

DROP TABLE IF EXISTS `person_birth_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_birth_details` (
  `person_birth_details_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `place_of_birth` int(11) NOT NULL,
  `district_of_birth` int(11) NOT NULL,
  `birth_location_id` int(11) NOT NULL,
  `other_birth_location` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `birth_weight` float DEFAULT NULL,
  `type_of_birth` int(11) NOT NULL,
  `other_type_of_birth` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parents_married_to_each_other` tinyint(4) NOT NULL DEFAULT '0',
  `date_of_marriage` date DEFAULT NULL,
  `gestation_at_birth` int(11) DEFAULT NULL,
  `number_of_prenatal_visits` int(11) DEFAULT NULL,
  `month_prenatal_care_started` int(11) DEFAULT NULL,
  `mode_of_delivery_id` int(11) DEFAULT NULL,
  `number_of_children_born_alive_inclusive` int(11) DEFAULT NULL,
  `number_of_children_born_still_alive` int(11) DEFAULT NULL,
  `level_of_education_id` int(11) DEFAULT NULL,
  `district_id_number` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `national_serial_number` bigint(20) DEFAULT NULL,
  `court_order_attached` tinyint(4) NOT NULL DEFAULT '0',
  `parents_signed` tinyint(4) NOT NULL DEFAULT '0',
  `acknowledgement_of_receipt_date` date NOT NULL,
  `facility_serial_number` varchar(30) COLLATE utf8_unicode_ci DEFAULT NULL,
  `adoption_court_order` tinyint(4) NOT NULL DEFAULT '0',
  `birth_registration_type_id` int(11) NOT NULL,
  `location_created_at` int(11) DEFAULT NULL,
  `form_signed` tinyint(4) NOT NULL DEFAULT '0',
  `informant_relationship_to_person` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `other_informant_relationship_to_person` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `informant_designation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `level` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `source_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `flagged` tinyint(4) NOT NULL DEFAULT '0',
  `date_reported` date NOT NULL,
  `date_registered` date DEFAULT NULL,
  `creator` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_birth_details_id`),
  UNIQUE KEY `district_id_number_UNIQUE` (`district_id_number`) USING BTREE,
  UNIQUE KEY `national_serial_number_UNIQUE` (`national_serial_number`) USING BTREE,
  KEY `fk_person_birth_details_3_idx` (`birth_location_id`) USING BTREE,
  KEY `fk_person_birth_details_8_idx` (`birth_registration_type_id`) USING BTREE,
  KEY `fk_person_birth_details_9` (`creator`) USING BTREE,
  KEY `fk_person_birth_details_7_idx` (`level_of_education_id`) USING BTREE,
  KEY `fk_person_birth_details_6_idx` (`location_created_at`) USING BTREE,
  KEY `fk_person_birth_details_5_idx` (`mode_of_delivery_id`) USING BTREE,
  KEY `fk_person_birth_details_1_idx` (`person_id`) USING BTREE,
  KEY `fk_person_birth_details_4_idx` (`place_of_birth`) USING BTREE,
  KEY `fk_person_birth_details_2_idx` (`type_of_birth`) USING BTREE,
  KEY `idx_detail_person_id` (`person_id`),
  KEY `idx_detail_location_created_at` (`location_created_at`),
  KEY `idx_detail_place_of_birth` (`place_of_birth`),
  KEY `idx_detail_district_of_birth` (`district_of_birth`),
  KEY `idx_detail_birth_location_id` (`birth_location_id`),
  KEY `idx_detail_level_of_education` (`level_of_education_id`),
  KEY `idx_detail_type_of_birth` (`type_of_birth`),
  KEY `idx_detail_ben` (`district_id_number`),
  KEY `idx_detail_brn` (`national_serial_number`),
  CONSTRAINT `fk_person_birth_details_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_birth_details_2` FOREIGN KEY (`place_of_birth`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_birth_details_3` FOREIGN KEY (`birth_location_id`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_birth_details_4` FOREIGN KEY (`level_of_education_id`) REFERENCES `level_of_education` (`level_of_education_id`),
  CONSTRAINT `fk_person_birth_details_5` FOREIGN KEY (`mode_of_delivery_id`) REFERENCES `mode_of_delivery` (`mode_of_delivery_id`),
  CONSTRAINT `fk_person_birth_details_6` FOREIGN KEY (`location_created_at`) REFERENCES `location` (`location_id`),
  CONSTRAINT `fk_person_birth_details_7` FOREIGN KEY (`type_of_birth`) REFERENCES `person_type_of_births` (`person_type_of_birth_id`),
  CONSTRAINT `fk_person_birth_details_8` FOREIGN KEY (`birth_registration_type_id`) REFERENCES `birth_registration_type` (`birth_registration_type_id`),
  CONSTRAINT `fk_person_birth_details_9` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100279105797 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_identifier_types`
--

DROP TABLE IF EXISTS `person_identifier_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_identifier_types` (
  `person_identifier_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `document_id` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_identifier_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_identifiers`
--

DROP TABLE IF EXISTS `person_identifiers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_identifiers` (
  `person_identifier_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `person_identifier_type_id` int(11) NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `value` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `document_id` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_identifier_id`),
  KEY `fk_person_identifiers_2_idx` (`person_identifier_type_id`) USING BTREE,
  KEY `fk_person_identifiers_1_idx` (`person_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1002793613083 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_name`
--

DROP TABLE IF EXISTS `person_name`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_name` (
  `person_name_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `first_name` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `middle_name` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_name_id`),
  KEY `fk_person_name_1_idx` (`person_id`) USING BTREE,
  KEY `fk_person_name_2_idx` (`voided_by`) USING BTREE,
  KEY `idx_first_name` (`first_name`),
  KEY `idx_last_name` (`last_name`),
  KEY `idx_middle_name` (`middle_name`),
  KEY `idx_name_person_id` (`person_id`),
  CONSTRAINT `fk_person_name_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_name_2` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=135077204817 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_name_code`
--

DROP TABLE IF EXISTS `person_name_code`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_name_code` (
  `person_name_code_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_name_id` bigint(20) NOT NULL,
  `first_name_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL,
  `middle_name_code` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name_code` varchar(10) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_name_code_id`),
  KEY `fk_person_name_code_1_idx` (`person_name_id`) USING BTREE,
  CONSTRAINT `fk_person_name_code_1` FOREIGN KEY (`person_name_id`) REFERENCES `person_name` (`person_name_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13572611726 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_record_statuses`
--

DROP TABLE IF EXISTS `person_record_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_record_statuses` (
  `person_record_status_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `status_id` int(11) NOT NULL,
  `person_id` bigint(20) NOT NULL,
  `creator` bigint(20) NOT NULL,
  `voided` tinyint(4) DEFAULT NULL,
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `comments` text COLLATE utf8_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_record_status_id`),
  KEY `fk_person_record_statuses_1_idx` (`person_id`) USING BTREE,
  KEY `fk_person_record_statuses_2_idx` (`status_id`) USING BTREE,
  KEY `fk_person_record_statuses_3_idx` (`voided_by`) USING BTREE,
  KEY `idx_detail_person_id` (`person_id`),
  KEY `idx_status_status_id` (`status_id`),
  CONSTRAINT `fk_person_record_statuses_1` FOREIGN KEY (`person_id`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_record_statuses_2` FOREIGN KEY (`status_id`) REFERENCES `statuses` (`status_id`),
  CONSTRAINT `fk_person_record_statuses_3` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100280422204 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_relationship`
--

DROP TABLE IF EXISTS `person_relationship`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_relationship` (
  `person_relationship_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_a` bigint(20) NOT NULL,
  `person_b` bigint(20) NOT NULL,
  `person_relationship_type_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`person_relationship_id`),
  KEY `fk_person_relationship_1_idx` (`person_a`) USING BTREE,
  KEY `fk_person_relationship_2_idx` (`person_b`) USING BTREE,
  KEY `fk_person_relationship_3_idx` (`person_relationship_type_id`) USING BTREE,
  CONSTRAINT `fk_person_relationship_1` FOREIGN KEY (`person_a`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_relationship_2` FOREIGN KEY (`person_b`) REFERENCES `core_person` (`person_id`),
  CONSTRAINT `fk_person_relationship_3` FOREIGN KEY (`person_relationship_type_id`) REFERENCES `person_relationship_types` (`person_relationship_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=135077168303 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_relationship_types`
--

DROP TABLE IF EXISTS `person_relationship_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_relationship_types` (
  `person_relationship_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(25) COLLATE utf8_unicode_ci NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `description` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  PRIMARY KEY (`person_relationship_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_type`
--

DROP TABLE IF EXISTS `person_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_type` (
  `person_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`person_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `person_type_of_births`
--

DROP TABLE IF EXISTS `person_type_of_births`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `person_type_of_births` (
  `person_type_of_birth_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `voided` tinyint(4) NOT NULL DEFAULT '0',
  `void_reason` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `voided_by` bigint(20) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  PRIMARY KEY (`person_type_of_birth_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `potential_duplicates`
--

DROP TABLE IF EXISTS `potential_duplicates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `potential_duplicates` (
  `potential_duplicate_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `resolved` varchar(1) COLLATE utf8_unicode_ci NOT NULL DEFAULT '0',
  `decision` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `comment` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`potential_duplicate_id`),
  KEY `fk_potential_duplicates_1` (`person_id`),
  CONSTRAINT `fk_potential_duplicates_1` FOREIGN KEY (`person_id`) REFERENCES `person` (`person_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10025016288 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `record_checks`
--

DROP TABLE IF EXISTS `record_checks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `record_checks` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `person_id` bigint(20) NOT NULL,
  `outcome` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `role` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role` varchar(50) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `level` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`role_id`),
  KEY `fk_user_role_1_idx` (`role_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schema_migrations`
--

DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_sessions_on_session_id` (`session_id`) USING BTREE,
  KEY `index_sessions_on_updated_at` (`updated_at`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3488 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `statuses`
--

DROP TABLE IF EXISTS `statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statuses` (
  `status_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=63 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `syncs`
--

DROP TABLE IF EXISTS `syncs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `syncs` (
  `sync_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `level` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `person_id` bigint(20) DEFAULT NULL,
  `rev` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`sync_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_role`
--

DROP TABLE IF EXISTS `user_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_role` (
  `user_role_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL,
  `role_id` int(11) NOT NULL,
  PRIMARY KEY (`user_role_id`),
  KEY `fk_user_role_2_idx` (`role_id`) USING BTREE,
  KEY `fk_user_role_1_idx` (`user_id`) USING BTREE,
  CONSTRAINT `fk_user_role_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `fk_user_role_2` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=100279192 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

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
) ENGINE=InnoDB AUTO_INCREMENT=100279192 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-10-16 18:38:45
