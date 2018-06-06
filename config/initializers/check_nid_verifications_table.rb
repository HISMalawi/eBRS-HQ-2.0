
ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `nid_verification_data` (
      `person_id` INT(20) NOT NULL,
      `passed` SMALLINT(6) NOT NULL,
      `data`   TEXT,
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`person_id`));
EOF