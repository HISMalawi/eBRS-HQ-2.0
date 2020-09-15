status_id = Status.where(name: "HQ-CAN-PRINT").first.id
person_ids = PersonRecordStatus.find_by_sql("
         SELECT d.person_id FROM person_birth_details d
        INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
        WHERE d.person_id LIKE '100250%' AND d.source_id IS NOT NULL
         AND d.source_id LIKE '-%#%' AND d.created_at > '2020-01-01'  AND prs.status_id = #{status_id} AND prs.voided = 0
         ").map(&:person_id).uniq

puts person_ids.count
#raise '######'.to_s
#user = User.where(username: "admin279").first



#person_ids = PersonBirthDetail.where(" created_at > '2018-12-31' and person_id > 10026416466").map(&:person_id)
person_ids.each_with_index do |pid, i|
        #a = PersonRecordStatus.where(person_id: pid, voided: 0).last
        #next if a.blank?
        #if a.status_id == 44
                #puts "#{(i + 1)} # pid: #{pid}"
                #PersonService.force_sync_remote(pid)
	b = PersonService.request_nris_id(pid, "N/A", 1002792) rescue nil
        puts "#{pid}: #{b}"
        #end
end

