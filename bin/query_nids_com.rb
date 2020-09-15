status_id = Status.where(name: "HQ-CAN-PRINT").first.id
person_ids = PersonRecordStatus.find_by_sql("
	 SELECT prs.person_id FROM person_record_statuses prs
	INNER JOIN person_birth_details d ON d.person_id = prs.person_id 
	WHERE d.source_id LIKE '%#%' AND prs.status_id = #{status_id} AND prs.voided = 0	 
").map(&:person_id).uniq

puts person_ids.count
user = User.where(username: "admin279").first

person_ids.each do |person_id|
  d = PersonBirthDetail.where(person_id: person_id).first
  d.generate_brn
#  PersonService.request_nris_ids_by_batch(chunk, "N/A", user)
end
