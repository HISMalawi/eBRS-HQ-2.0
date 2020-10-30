queue = PersonBirthDetail.where(" source_id LIKE '%-%' ")
queue.each_with_index do |record, indexx|
	puts indexx
		status = PersonRecordStatus.status(record.person_id)
		if status != 'HQ-CAN-PRINT'
			record.national_serial_number = nil
			record.save
		end
end 
