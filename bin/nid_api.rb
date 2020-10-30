$district_name = ARGV[0]
$counter = 0
$codes = JSON.parse(File.read("#{Rails.root}/db/code2country.json"))
$user_id = User.where(username: 'admin279').first.id
$district_tag_id = LocationTag.where(name: "DISTRICT").first.id
$ta_tag_id = LocationTag.where(name: "TRADITIONAL AUTHORITY").first.id
$village_tag_id = LocationTag.where(name: "VILLAGE").first.id

PersonTypeOfBirth.create(
    name: "Unknown"
) if PersonTypeOfBirth.where(name: "Unknown").blank?

ModeOfDelivery.create(
    name: "Unknown"
) if ModeOfDelivery.where(name: "Unknown").blank?

LevelOfEducation.create(
    name: "Unknown"
) if LevelOfEducation.where(name: "Unknown").blank?

l = Location.create(
    name: "Mass Data Location",
    code: "LL"
) if Location.where(name: "Mass Data Location").blank?

$missing_districts      = []
$missing_tas            = []
$missing_villages       = []
$exact_duplicates       = []
$potential_duplicates   = []
$success                = []
$incomplete_records     = []
$other_country          = []
$records_with_special_character_names = []
$missing_tas_records       = []
$missing_districts_records = []
$missing_villages_records  = []

$registered_after_mass_reg        = []
$registered_before_mass_reg       = []
$registered_after_16_years        = []
$have_now_reached_16_years        = []

def format_person(hash, person_id=nil)

  person = {}
  person["id"] = person_id
  person["first_name"]= hash["FirstName"] rescue ''
  person["last_name"] =  hash["Surname"] rescue ''
  person["middle_name"] = hash["OtherNames"] rescue ''
  person["gender"] = hash["Sex"]
  person["birthdate"]= hash["DateOfBirthString"].to_date
  person["birthdate_estimated"] = 0
  person["nationality"]=  $codes[hash["Nationality"]]
  person["place_of_birth"] = "Other"
  person["district"] = hash["PlaceOfBirthDistrictName"]

  person["mother_first_name"]= hash["MotherFirstName"]
  person["mother_last_name"] =  hash["MotherSurname"]
  person["mother_middle_name"] = hash["MotherOtherNames"]

  person["mother_home_district"] = hash["MotherDistrictName"]
  person["mother_home_ta"] = hash["MotherTaName"]
  person["mother_home_village"] = hash["MotherVillageName"]

  person["mother_current_district"] = nil
  person["mother_current_ta"] = nil
  person["mother_current_village"] = nil

  person["father_first_name"]= hash["FatherFirstName"]
  person["father_last_name"] =  hash["FatherSurname"]
  person["father_middle_name"] = hash["FatherOtherNames"]

  person["father_home_district"] = hash["FatherDistrictName"]
  person["father_home_ta"] = hash["FatherTaName"]
  person["father_home_village"] = hash["FatherVillageName"]

  person["father_current_district"] = nil
  person["father_current_ta"] = nil
  person["father_current_village"] = nil
  person
end

def assign_next_brn(person_id)

  last = (PersonBirthDetail.select(" MAX(national_serial_number) AS last_num")[0]['last_num'] rescue 0).to_i
  birth_detail = PersonBirthDetail.where(person_id: person_id).first
  brn = last + 1
  birth_detail.update_attributes(national_serial_number: brn)

  PersonIdentifier.new_identifier(person_id,
                                  'Birth Registration Number', birth_detail.national_serial_number)

  brn
end

def assign_next_ben(person_id, district_code)

  $counter = $counter.to_i + 1
  mid_number = $counter.to_s.rjust(8,'0')
  ben = "#{district_code}/#{mid_number}/2017"
  ActiveRecord::Base.connection.execute <<EOF
    UPDATE person_birth_details SET district_id_number = '#{ben}' WHERE person_id = #{person_id}
EOF

  PersonIdentifier.new_identifier(person_id, 'Birth Entry Number', ben)

  ben
end

def mass_data(district_n = $district_name)
  $district_name = district_n

  district = Location.find_by_sql(
      ["SELECT * FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
          AND m.location_tag_id = #{$district_tag_id}
        WHERE l.name = '#{district_n}' "]).first

  district_name = district.name rescue (raise district_n.inspect)
  district_code = district.code
  puts "DISTRICT: #{district_name}, CODE: #{district_code}"

  if district_code.blank?
    raise "Missing District Code".inspect
  end

  last_2017_ben = ActiveRecord::Base.connection.execute <<EOF
    SELECT MAX(district_id_number) ben FROM person_birth_details WHERE district_id_number LIKE '#{district_code}/%2017';
EOF


  last_2017_ben2 = ActiveRecord::Base.connection.execute <<EOF
    SELECT MAX(value) ben FROM person_identifiers WHERE value LIKE '#{district_code}/%2017';
EOF

  puts "#{district_n} New BEN: " + last_2017_ben2.first[0]
  puts "#{district_n} Old BEN: " + last_2017_ben.first[0]

  if last_2017_ben.first[0].blank?
    return nil
  end

  last_2017_ben =  [last_2017_ben.first[0].split("/")[1].to_i, last_2017_ben2.first[0].split("/")[1].to_i].max

  $counter = last_2017_ben
  puts $counter
  puts "Last BEN: #{$counter}"

  columns = ActiveRecord::Base.connection.execute <<EOF
    SHOW columns FROM mass_data;
EOF

  columns = columns.collect{|c| c[0]}
  $exact_duplicates << columns.join(",")
  $potential_duplicates << columns.join(",")
  $success << columns.join(",")

  $missing_districts      << ["District"].join(",")
  $missing_tas            << ["District", "TA"].join(",")
  $missing_villages       << ["District", "TA", "Village"].join(",")

  $missing_tas_records            << columns.join(",")
  $missing_districts_records      << columns.join(",")
  $missing_villages_records       << columns.join(",")

  $registered_after_mass_reg      << columns.join(",")
  $incomplete_records      << columns.join(",")
  $other_country           << columns.join(",")
  $records_with_special_character_names  << columns.join(",")
  $registered_before_mass_reg << columns.join(",")
  $registered_after_16_years  << columns.join(",")
  $have_now_reached_16_years << columns.join(",")
  district_name = "NKHOTA-KOTA" if district_name.upcase == "NKHOTAKOTA"

  data = ActiveRecord::Base.connection.execute <<EOF
     SELECT * FROM mass_data
  WHERE category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
  AND DistrictOfRegistration IN ('#{district_name}') AND load_status IS NULL;
EOF

=begin
  ActiveRecord::Base.connection.execute <<EOF
    UPDATE mass_data SET load_status = NULL WHERE DistrictOfRegistration = '#{district_name}'
      AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
EOF
=end

  #bar = ProgressBar.new(data.count)
  data.each_with_index do |nid_child, index|
    #bar.increment!
    hash = {}
    nid_child.each_with_index do |value, i|
      value = (value.to_s.split.map(&:capitalize).join(' ') rescue value) unless ["FathePin", "MotherPin", "DateOfBirthString"].include?(columns[i])
      hash[columns[i]] = value
    end

    already_loaded =  (PersonBirthDetail.where(source_id: nid_child[0]).count > 0)

    ActiveRecord::Base.transaction do
      hash = hash.with_indifferent_access
      hash["PlaceOfBirthDistrictName"] = "Nkhotakota" if hash["PlaceOfBirthDistrictName"].to_s.strip.upcase == "NKHOTA-KOTA"
      hash["DistrictOfRegistration"] = "Nkhotakota" if hash["DistrictOfRegistration"].to_s.strip.upcase == "NKHOTA-KOTA"
      hash["MotherDistrictName"] = "Nkhotakota" if hash["MotherDistrictName"].to_s.strip.upcase == "NKHOTA-KOTA"
      hash["FatherDistrictName"] = "Nkhotakota" if hash["FatherDistrictName"].to_s.strip.upcase == "NKHOTA-KOTA"

      load_status = "Success"

      #Filter for names with special characters
      if load_status == "Success"
        [hash["Surname"], hash["OtherNames"], hash["FirstName"], hash["MotherFirstName"], hash["MotherSurname"], hash["MotherOtherNames"],
         hash["FatherSurname"], hash["FatherFirstName"], hash["FatherOtherNames"]].each do |name|

          if name.to_s.match(/[-!$%^&*()_+|~=`{}\[\]:";@\#<>?,.\/]|\d+/)
            load_status = "Name With Special Character"
            $records_with_special_character_names << nid_child.join(",")
          end
        end

      end

      #Filter for Complete Cases
      if load_status == "Success"
        if ([hash["Surname"], hash["FirstName"], hash["DateOfBirthString"], hash["Nationality"],
             hash["MotherSurname"], hash["MotherFirstName"], hash["MotherPin"], hash["MotherNationality"],
             hash["PlaceOfBirthDistrictName"], hash["PlaceOfBirthTAName"], hash["PlaceOfBirthVillageName"] ] & ["", nil]).length > 0

          load_status = "Record Incomplete"
          $incomplete_records << nid_child.join(",")
        end
      end

      #Validation for Father Details
      if load_status == "Success" && hash["Category"].to_s.strip == "Bothparents-biological-spousematched"

        if ([hash["FatherFirstName"], hash["FatherSurname"], hash["FatherPin"], hash["FatherNationality"]] & ["", nil]).length > 0

          load_status = "Record Incomplete"
          $incomplete_records << nid_child.join(",")
        end
      end

      #Filter For Other Country
      if load_status == "Success"
        if [hash["PlaceOfBirthDistrictName"], hash["PlaceOfBirthTaName"], hash["PlaceOfBirthVillageName"],
            hash[" MotherDistrictName"], hash[" MotherTAName"], hash[" MotherVillageName"],
            hash[" FatherDistrictName"], hash[" FatherTAName"], hash[" FatherVillageName"]].include?("Other Country")
          load_status = "Other Country"
          $other_country << nid_child.join(",")
        end
      end

      ds_loaded = false
      #Filter For Missing District
      if load_status == "Success"
        [hash["PlaceOfBirthDistrictName"], hash[" MotherDistrictName"], hash[" FatherDistrictName"]].each do |district|
          next if district.blank?
          found = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = \"#{district}\" AND tm.location_tag_id = #{$district_tag_id}
                                       ").length > 0

          if found == false
            load_status = "Missing District"
            $missing_districts << district
            $missing_districts_records << nid_child.join(",") if ds_loaded == false
            ds_loaded = true
          end
        end
      end

      #Filter For Missing TA
      ta_loaded = false
      if load_status == "Success"
        [[hash["PlaceOfBirthTAName"], hash["PlaceOfBirthDistrictName"]],
         [hash[" MotherTAName"], hash["MotherDistrictName"]],
         [hash[" FatherTAName"], hash["FatherDistrictName"]]].each do |ta, district|
          next if ta.blank? || district.blank?
          tas = [ta, ("SC " + ta), ("S/C " + ta), ("TA " + ta), ("STA " + ta)]
          district_id = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = \"#{district}\" AND tm.location_tag_id = #{$district_tag_id}
                                             ").first.location_id rescue nil
          found = (Location.find_by_sql(["
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name IN (?) AND tm.location_tag_id = #{$ta_tag_id} AND l.parent_location = #{district_id}
                                         ", tas]).length > 0)

          if found == false
            load_status = "Missing TA"
            $missing_tas << "#{district}, #{ta}"
            $missing_tas_records << nid_child.join(",") if ta_loaded == false
            ta_loaded = true
          end
        end
      end

      #Filter For Missing Village
      vg_loaded = false
      if load_status == "Success"
        [[hash["PlaceOfBirthVillageName"], hash["PlaceOfBirthTAName"], hash["PlaceOfBirthDistrictName"]],
         [hash[" MotherVillageName"], hash[" MotherTAName"], hash["MotherDistrictName"]],
         [hash[" FatherVillageName"], hash[" FatherTAName"], hash["FatherDistrictName"]]].each do |village, ta, district|
          next if village.blank? || ta.blank? || district.blank?

          tas = [ta, ("SC " + ta), ("S/C " + ta), ("TA " + ta), ("STA " + ta)]
          district_id = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = \"#{district}\" AND tm.location_tag_id = #{$district_tag_id}
                                             ").first.location_id rescue nil
          ta_id = Location.find_by_sql(["
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name IN (?) AND tm.location_tag_id = #{$ta_tag_id} AND l.parent_location = #{district_id}
                                        ", tas]).first.location_id

          found = (Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = \"#{village}\" AND tm.location_tag_id = #{$village_tag_id} AND l.parent_location = #{ta_id}
                                        ").length > 0)

          if found == false
            load_status = "Missing Village"
            $missing_villages << "#{district}, #{ta}, #{village}"
            $missing_villages_records << nid_child.join(",") if vg_loaded == false
            vg_loaded = true
          end
        end
      end

      #Registered After Mass Data
      if hash["DateRegistered"].to_date >= "01/11/2017".to_date
        load_status = "Registered After Mass Registration"
        $registered_after_mass_reg << nid_child.join(",")
      end

      if hash["DateRegistered"].to_date < "01/07/2017".to_date
        load_status = "Registered Before Mass Registration"
        $registered_before_mass_reg << nid_child.join(",")
      end

      if (Date.today - hash["DateOfBirthString"].to_date).to_i/365.0 >= 16.0
        load_status = "Have Now Reached 16 Years"
        $have_now_reached_16_years << nid_child.join(",")
      end

      if (hash["DateRegistered"].to_date - hash["DateOfBirthString"].to_date).to_i/365.0 >= 16
        load_status = "Registered After 16 Years"
        $registered_after_16_years << nid_child.join(",")
      end


      #Filter for Existing mother
      #Filter for Existing father

      status = "HQ-CAN-PRINT"
      person = format_person(hash, 0)
      exact_duplicates = SimpleElasticSearch.query_duplicate_coded(person, 100)
      exact_duplicates.delete_if{|e| e['id'].to_s.match(/^135764/)}

      next if already_loaded

      if exact_duplicates.present?
        load_status = "Exact Duplicate(s) Found"
        status = "HQ-EXACT-DUPLICATE"
        puts load_status
        $exact_duplicates << nid_child.join(",")
      elsif load_status == "Success"

        person_id  = PersonService.create_nris_person(hash)
        hash['id'] = person_id
        duplicates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])
        duplicates.delete_if{|e| e['id'].to_s.match(/^135764/)}

        if duplicates.present?
          load_status = "Potential Duplicate(s) Found"
          puts load_status

          $potential_duplicates << nid_child.join(",")
          results = []
          duplicates.each do |dup|
            next if DuplicateRecord.where(person_id: person['id']).present?
            results << dup if PotentialDuplicate.where(person_id: dup['_id']).blank?
          end

          if results.present?
            potential_duplicate = PotentialDuplicate.create(person_id: person_id, created_at: (Time.now))
            if potential_duplicate.present?
              results.each do |result|
                potential_duplicate.create_duplicate(result["_id"]) rescue nil
              end
            end

            status = "HQ-POTENTIAL DUPLICATE-TBA"
          end
        end

        if load_status == "Success"
          $success << nid_child.join(",")
        end

        #Assign Birth Entry Number - BEN
        ben = assign_next_ben(person_id, district_code)

        #Assign Birth Registration Number - BRN
        brn = nil
        brn = assign_next_brn(person_id) if status != "HQ-POTENTIAL DUPLICATE-TBA"
        puts "#{person_id} # #{ben } # #{brn}"

        #Initialize record status
        s = PersonRecordStatus.new
        s.person_id = person_id
        s.voided = 0
        s.status_id = Status.where(name: status).first.id
        s.comments = "New Record From Mass Data"
        s.creator = $user_id
        s.save

        SimpleElasticSearch.add(person)
      end

      ActiveRecord::Base.connection.execute <<EOF
    UPDATE mass_data SET load_status = '#{load_status}' WHERE id = #{nid_child[0]}
EOF

    end
  end

  puts "#{data.count} Records Checked"
end

puts "Mass Data Import Started"

districts_registered = ActiveRecord::Base.connection.execute <<EOF
    SELECT DISTINCT(DistrictOfRegistration) FROM mass_data;
EOF

districts_registered = (["Dowa", "Kasungu"] + districts_registered.as_json.flatten.sort)
districts_registered.each do |d|
  next if d.upcase.strip == "LIKOMA"
  d = "NKHOTAKOTA" if d.upcase == "NKHOTA-KOTA"

  $missing_districts      = []
  $missing_tas            = []
  $missing_villages       = []
  $exact_duplicates       = []
  $potential_duplicates   = []
  $success                = []
  $incomplete_records     = []
  $other_country          = []
  $records_with_special_character_names = []
  $missing_tas_records       = []
  $missing_districts_records = []
  $missing_villages_records  = []

  $registered_after_mass_reg        = []
  $registered_before_mass_reg       = []
  $registered_after_16_years        = []
  $have_now_reached_16_years        = []

  mass_data(d)

  File.open("data/#{$district_name.upcase}-missing_district_#{$missing_districts_records.count - 1}.csv", "w"){|f| f.write($missing_districts.uniq.join("\n"))}
  File.open("data/#{$district_name.upcase}-missing_tas_#{$missing_tas_records.count - 1}.csv", "w"){|f| f.write($missing_tas.uniq.join("\n"))}
  File.open("data/#{$district_name.upcase}-missing_villages_#{$missing_villages_records.count - 1}.csv", "w"){|f| f.write($missing_villages.uniq.join("\n"))}
  File.open("data/#{$district_name.upcase}-potential_duplicates_#{$potential_duplicates.count - 1}.csv", "w"){|f| f.write($potential_duplicates.join("\n"))}
  File.open("data/#{$district_name.upcase}-exact_duplicates_#{$exact_duplicates.count - 1}.csv", "w"){|f| f.write($exact_duplicates.join("\n"))}
  File.open("data/#{$district_name.upcase}-incomplete_records_#{$incomplete_records.count - 1}.csv", "w"){|f| f.write($incomplete_records.join("\n"))}
  File.open("data/#{$district_name.upcase}-other_country_#{$other_country.count - 1}.csv", "w"){|f| f.write($other_country.join("\n"))}
  File.open("data/#{$district_name.upcase}-successfull_#{$success.count - 1}.csv", "w"){|f| f.write($success.join("\n"))}
  File.open("data/#{$district_name.upcase}-registered_after_mass_#{$registered_after_mass_reg.count - 1}.csv", "w"){|f| f.write($registered_after_mass_reg.join("\n"))}
  File.open("data/#{$district_name.upcase}-records_with_special_characters_names_#{$records_with_special_character_names.count - 1}.csv", "w"){|f| f.write($records_with_special_character_names.join("\n"))}
  File.open("data/#{$district_name.upcase}-registered_before_mass_reg_#{$registered_before_mass_reg.count - 1}.csv", "w"){|f| f.write($registered_before_mass_reg.join("\n"))}
  File.open("data/#{$district_name.upcase}-registered_after_16_years_#{$registered_after_16_years.count - 1}.csv", "w"){|f| f.write($registered_after_16_years.join("\n"))}
  File.open("data/#{$district_name.upcase}-have_now_reached_16_years_#{$have_now_reached_16_years.count - 1}.csv", "w"){|f| f.write($have_now_reached_16_years.join("\n"))}
end


