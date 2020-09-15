status_id = Status.where(name: "HQ-CAN-PRINT").first.id
person_ids = PersonRecordStatus.find_by_sql("
         SELECT d.person_id FROM person_birth_details d
        INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
        WHERE d.national_serial_number IS NULL
        AND prs.status_id = #{status_id} AND prs.voided = 0
         ").map(&:person_id).uniq

puts person_ids.count
#raise '######'.to_s
user = User.where(username: "admin279").first

person_ids.each_with_index do |person_id, i|

  d = PersonBirthDetail.where(person_id: person_id).first
  ben = d.district_id_number rescue nil
  brn = d.generate_brn
  d.save

  if ben.blank?
     identifier = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: 2).first
     birth_entry_number = identifier.value rescue nil
     date_registered = identifier.create_at rescue nil
     d.district_id_number = birth_entry_number rescue nil
     d.date_registered = date_registered rescue nil
     d.save
  end

  ben2 = d.district_id_number rescue nil

  puts "#{(i + 1)} ## #{person_id} ## #{brn} ## #{ben2}"
end

