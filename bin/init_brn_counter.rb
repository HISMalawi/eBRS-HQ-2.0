
ActiveRecord::Base.connection.execute <<EOF
    CREATE TABLE IF NOT EXISTS `brn_counter` (
      `counter` BIGINT(20) NOT NULL AUTO_INCREMENT,
      `person_id` BIGINT(20) NOT NULL,
      `created_at`  TIMESTAMP NOT NULL,
      PRIMARY KEY (`counter`),
      UNIQUE INDEX `counter_UNIQUE` (`counter` ASC),
	  UNIQUE INDEX `pid_UNIQUE` (`person_id` ASC)
	);
EOF

last_counter = ActiveRecord::Base.connection.select_one("SELECT MAX(counter) AS counter FROM brn_counter").as_json['counter']
if last_counter.blank?
	#Set last brn from birth details
	last_brn = ActiveRecord::Base.connection.select_one("SELECT MAX(national_serial_number) AS brn FROM person_birth_details").as_json['brn'];

	if !last_brn.blank? 	
		counter = last_brn
		person_id = ActiveRecord::Base.connection.select_one("SELECT person_id FROM person_birth_details WHERE national_serial_number = '#{last_brn}' ").as_json['person_id'];
		
		puts "Query Execution:  INSERT INTO brn_counter(counter, person_id) VALUES (#{person_id}, #{counter})"
		ActiveRecord::Base.connection.execute("INSERT INTO brn_counter(counter, person_id) VALUES (#{counter}, #{person_id})")
	end 
end 


