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
  district = Location.find_by_sql(
      ["SELECT * FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
          AND m.location_tag_id = #{$district_tag_id}
        WHERE l.name = '#{district_n}' "]).first

  district_name = district.name
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

  if last_2017_ben.first[0].blank?
    return nil
  end

  puts [last_2017_ben.first[0], last_2017_ben2.first[0]]
  last_2017_ben =  [last_2017_ben.first[0], last_2017_ben2.first[0]].max

  puts last_2017_ben

  $counter = last_2017_ben.split("/")[1].to_i
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

  data = ActiveRecord::Base.connection.execute <<EOF
     SELECT * FROM mass_data
  WHERE category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
  AND DistrictOfRegistration IN ('#{district_name}');
EOF

=begin
  ActiveRecord::Base.connection.execute <<EOF
    UPDATE mass_data SET load_status = NULL WHERE DistrictOfRegistration = '#{district_name}'
      AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
EOF
=end

  bar = ProgressBar.new(data.count)
  data.each_with_index do |nid_child, index|
    bar.increment!
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

    end
  end

  puts "#{data.count} Records Checked"
end

puts "Mass Data Import Started"

districts_registered = ActiveRecord::Base.connection.execute <<EOF
    SELECT DISTINCT(DistrictOfRegistration) FROM mass_data;
EOF

districts_registered = districts_registered.as_json.flatten
districts_registered.each do |d|
  mass_data(d)
end

File.open("#{$district_name.upcase}-missing_district_#{$missing_districts_records.count - 1}.csv", "w"){|f| f.write($missing_districts.uniq.join("\n"))}
File.open("#{$district_name.upcase}-missing_tas_#{$missing_tas_records.count - 1}.csv", "w"){|f| f.write($missing_tas.uniq.join("\n"))}
File.open("#{$district_name.upcase}-missing_villages_#{$missing_villages_records.count - 1}.csv", "w"){|f| f.write($missing_villages.uniq.join("\n"))}
File.open("#{$district_name.upcase}-potential_duplicates_#{$potential_duplicates.count - 1}.csv", "w"){|f| f.write($potential_duplicates.join("\n"))}
File.open("#{$district_name.upcase}-exact_duplicates_#{$exact_duplicates.count - 1}.csv", "w"){|f| f.write($exact_duplicates.join("\n"))}
File.open("#{$district_name.upcase}-incomplete_records_#{$incomplete_records.count - 1}.csv", "w"){|f| f.write($incomplete_records.join("\n"))}
File.open("#{$district_name.upcase}-other_country_#{$other_country.count - 1}.csv", "w"){|f| f.write($other_country.join("\n"))}
File.open("#{$district_name.upcase}-successfull_#{$success.count - 1}.csv", "w"){|f| f.write($success.join("\n"))}
File.open("#{$district_name.upcase}-registered_after_mass_#{$registered_after_mass_reg.count - 1}.csv", "w"){|f| f.write($registered_after_mass_reg.join("\n"))}
File.open("#{$district_name.upcase}-records_with_special_characters_names_#{$records_with_special_character_names.count - 1}.csv", "w"){|f| f.write($records_with_special_character_names.join("\n"))}
File.open("#{$district_name.upcase}-registered_before_mass_reg_#{$registered_before_mass_reg.count - 1}.csv", "w"){|f| f.write($registered_before_mass_reg.join("\n"))}
File.open("#{$district_name.upcase}-registered_after_16_years_#{$registered_after_16_years.count - 1}.csv", "w"){|f| f.write($registered_after_16_years.join("\n"))}
File.open("#{$district_name.upcase}-have_now_reached_16_years_#{$have_now_reached_16_years.count - 1}.csv", "w"){|f| f.write($have_now_reached_16_years.join("\n"))}
