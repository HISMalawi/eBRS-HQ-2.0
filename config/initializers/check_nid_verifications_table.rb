
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