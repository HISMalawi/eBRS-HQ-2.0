lines = File.read("mass_record_ids_incomplete").split("\n")
File.open("incomplete_records2", "w"){|f| f.write("mass_person_id|BEN|BRN|NationalID")}
cur_user = User.where(username: "admin279").first

lines.each do |line|
	line = line.strip
	detail = PersonBirthDetail.where("source_id LIKE '-#{line}#%' AND person_id LIKE '100271%' ").last

	#status = PersonRecordStatus.status(detail.person_id)
        #puts status
#	next

#	#if status.upcase.match("INCOMPLETE")
#		puts "CHANGING STATUS"
#		
#		PersonRecordStatus.new_record_state(detail.person_id, "HQ-CAN-PRINT", "", cur_user.id)
#	end 
        
 #        next
#	if detail.brn.blank?
#		puts "ASSIGNING BRN"
#		detail.generate_brn
#	end

#	if detail.national_id.blank? 
#		puts "ASSIGNING NID"
#		PersonService.request_nris_id(detail.person_id, "N/A", cur_user)
#	end

	data = "\n#{line}|#{detail.district_id_number}|#{detail.brn}|#{detail.national_id}"

	puts data
	File.open("incomplete_records2", "a"){|f| f.write(data)}
end
