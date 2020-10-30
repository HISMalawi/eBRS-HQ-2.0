query = "SELECT `person_id`, count(*) as status_count 
		FROM `person_record_statuses` WHERE `voided` = '0'  
		GROUP BY  `person_id` ORDER BY status_count DESC;"
ActiveRecord::Base.connection.select_all(query).as_json.each do |row|
    next if row["status_count"].to_i == 1
    statuses = PersonRecordStatus.where(person_id: row['person_id']).order('created_at DESC')
    statuses.each_with_index do |s, i|
        next if i == 0
	state = Status.find(s.status_id)
        puts "#{state.name} #{s.person_id} #{i} #{s.created_at}"
	begin
		s.voided = 1
		s.save
	rescue Exception => e
		puts "#{row['person_id']} : #{e.to_s}"
	end
    end

end