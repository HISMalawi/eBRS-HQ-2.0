
ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `nid_verification_data` (
      `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `person_id` BIGINT(20) NOT NULL,
      `passed` SMALLINT(6) NOT NULL,
      `data`   TEXT,
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE INDEX `id_UNIQUE` (`id` ASC));
EOF

ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `error_records` (
      `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `person_id` BIGINT(20) NOT NULL,
      `passed` SMALLINT(6) NOT NULL,
      `table_name`   VARCHAR(255),
      `data`   TEXT,
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE INDEX `id_UNIQUE` (`id` ASC));
EOF

ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `record_checks` (
      `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `person_id` BIGINT(20) NOT NULL,
      `outcome` VARCHAR(255),
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE INDEX `id_UNIQUE` (`id` ASC));
EOF

ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `certificate` (
      `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `person_id` BIGINT(20) NOT NULL,
      `date_printed` DATETIME,
      `date_dispatched` DATETIME,
      `print_count` INT,
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE INDEX `id_UNIQUE` (`id` ASC));
EOF