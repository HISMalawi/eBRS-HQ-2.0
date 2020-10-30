#status_id = Status.where(name: "HQ-CAN-PRINT").first.id
#person_ids = PersonRecordStatus.find_by_sql("
#	 SELECT d.person_id FROM person_birth_details d
#	INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
#	WHERE d.person_id LIKE '100250%' AND d.source_id IS NOT NULL 
#	 AND d.source_id LIKE '-%#%'  AND prs.status_id = #{status_id} AND prs.voided = 0
#	 ").map(&:person_id).uniq
#person_ids = File.read("missing_nids.csv").split("\n")
#puts person_ids.count
#raise '######'.to_s
#user = User.where(username: "admin279").first

#person_ids.each_slice(100).each_with_index do |chunk, i|
 # next if (i + 1) != 1
#  puts "Chunck #{(i + 1)}"
#  PersonService.request_nris_ids_by_batch(chunk, "N/A", user)
#end

person_ids = File.read("missing_nids.csv").split("\n")
person_ids.each_with_index do |person_id, i|
  d = PersonBirthDetail.where(person_id: person_id).first
  File.open("missing_nids3", "a"){|f|
    f.write("#{person_id}|#{d.national_id}\n")
  }
end
