status_id = Status.where(name: "HQ-POTENTIAL DUPLICATE").first.id

person_ids = PersonRecordStatus.find_by_sql("
	 SELECT d.person_id FROM person_birth_details d
	INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
	WHERE prs.status_id = #{status_id} AND prs.voided = 0 AND d.district_id_number like 'NS/%' 
	AND prs.comments = 'Potential Duplicate' AND prs.created_at > '2020-09-09'
	 ").map(&:person_id).uniq

puts person_ids.count
#raise '######'.to_s
user = User.where(username: "admin279").first.id

#raise user.inspect

person_ids.each_with_index do |person_id, i|

		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.destroy

		new_status = PersonRecordStatus.where(person_id: person_id, status_id: 8).last
		new_status.voided = 0
		new_status.save

		puts "#{person_id}: Pushed back to active by autocheck"

	

end #end loop