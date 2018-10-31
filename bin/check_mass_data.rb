def format_person(hash, person_id=nil)
  hash = PersonBirthDetail.first
  person_id = hash.person_id
  name = PersonName.where(person_id: person_id).first
  person = Person.find(person_id)
  mother_name = PersonName.mother(person_id)
  father_name = PersonName.father(person_id)
  mother_address = PersonService.mother_address(person_id)
  father_address = PersonService.father_address(person_id)

  person = {}
  person["id"] = person_id
  person["first_name"]= name["first_name"] rescue ''
  person["last_name"] =  name["last_name"] rescue ''
  person["middle_name"] = name["middle_name"] rescue ''
  person["gender"] = {"F" => "Female", "M" => "Male", "N/A" => nil}[person["gender"]] || person["gender"]
  person["birthdate"]= person["birthdate"].to_date.to_s
  person["birthdate_estimated"] = 0
  person["nationality"]=  nil
  person["place_of_birth"] = Location.find(hash["place_of_birth"]).name
  person["district"] = Location.find(hash["location_created_at"]).district

  person["mother_first_name"]= mother_name["mother_first_name"]
  person["mother_last_name"] =  mother_name["mother_last_name"]
  person["mother_middle_name"] = name["mother_middle_name"]

  person["mother_home_district"] = nil
  person["mother_home_ta"] = nil
  person["mother_home_village"] = nil

  person["mother_current_district"] = nil
  person["mother_current_ta"] = nil
  person["mother_current_village"] = nil

  person["father_first_name"]= hash["father_first_name"]
  person["father_last_name"] =  hash["father_last_name"]
  person["father_middle_name"] = hash["father_middle_name"]

  person["father_home_district"] = nil
  person["father_home_ta"] = nil
  person["father_home_village"] = nil

  person["father_current_district"] = nil
  person["father_current_ta"] = nil
  person["father_current_village"] = nil
  person
end

pending_records  = PersonBirthDetail.find_by_sql(" SELECT count(*) FROM mass_data
                    WHERE INT(source_id) < 0 AND person_id NOT IN ( SELECT person_id FROM record_checks ) ")

User.current = User.where(username: "admin#{SETTINGS['location_id']}").last
response = "N"

ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE person_birth_details MODIFY number_of_children_born_alive_inclusive INT NULL
EOF

ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE person_birth_details MODIFY number_of_children_born_still_alive INT NULL
EOF

ActiveRecord::Base.connection.execute <<EOF
ALTER TABLE person_birth_details MODIFY number_of_prenatal_visits INT NULL
EOF

def assign_next_brn(person_id)

  last = (PersonBirthDetail.select(" MAX(national_serial_number) AS last_num")[0]['last_num'] rescue 0).to_i
  birth_detail = PersonBirthDetail.where(person_id: person_id).first
  brn = last + 1
  birth_detail.update_attributes(national_serial_number: brn)

  PersonIdentifier.new_identifier(person_id,
                                  'Birth Registration Number', birth_detail.national_serial_number)

  brn
end

if pending_records.count > 0
  puts "#{pending_records.count} Records to be Checked"

  puts "Proceed to load data Y/N"
  response = gets
else
  puts "No Records Found to for Auto Checks"
end

if ["YES", "Y"].include?(response.chomp.to_s.upcase)

  pending_records.each do |record|
    status = "HQ-CAN-PRINT"
    outcome = "Success"

    formated = format_person(record)
    exact_duplicates = SimpleElasticSearch.query_duplicate_coded(formated, 100)
    exact_duplicates.delete_if{|e| e["_id"].to_i == record.person_id.to_i}
    if exact_duplicates.length > 0
      outcome = "Exact Duplicate"
      status = "HQ-POTENTIAL DUPLICATE-TBA" #Still save as potential duplicate
    end

    potential_duplicates = SimpleElasticSearch.query_duplicate_coded(formated, 80)
    potential_duplicates.delete_if{|e| e["_id"].to_i == record.person_id.to_i}

    exact_duplicates_ids = exact_duplicates.collect{|e| e["_id"]}
    potential_duplicates.delete_if{|o| exact_duplicates_ids.include?(o["_id"]) }

    if potential_duplicates.length > 0
      outcome = "Potential Duplicate"
      status = "HQ-POTENTIAL DUPLICATE-TBA"
    end

    ActiveRecord::Base.transaction do

      if potential_duplicates.present?
        potential_duplicate = PotentialDuplicate.create(person_id: record.person_id, created_at: (Time.now))
        potential_duplicates.each do |result|
          potential_duplicate.create_duplicate(result["_id"]) #rescue nil
        end
      end

      RecordChecks.create(
          person_id: record.person_id,
          outcome:   outcome
      )

      brn = nil
      brn = assign_next_brn(person_id) if status != "HQ-POTENTIAL DUPLICATE-TBA"
      puts "#{record.person_id} # #{record.district_id_number } # #{brn}"

      PersonRecordStatus.new_record_state(record.person_id, status, "HQ Auto Check Status")
      SimpleElasticSearch.add(formated)
    end
  end

  puts "Done"
else
  puts "Stopped"
end
