$counter = 0
$codes = JSON.parse(File.read("#{Rails.root}/db/code2country.json"))
$user_id = User.where(username: 'admin279').first
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

def mass_data
=begin
    data = [{
        "Surname"=> "Ferrirad",
        "OtherNames"=> "Moses",
        "FirstName"=> "Masula",
        "DateOfBirthString"=>"02/12/2017",
        "Sex"=> 1,
        "Nationality"=> "MWI",
        "Nationality2"=> "",
        "Status"=>"Normal",
        "TypeOfBirth" => "Single",
        "ModeOfDelivery" => "Breech",
        "LevelOfEducation" => "none",
        "MotherPin"=> '4BSBY839',
        "MotherSurname"=> "Banda",
        "MotherMaidenName"=> "Mwandala",
        "MotherFirstName"=> "Zeliya",
        "MotherOtherNames"=>"Julia",
        "MotherNationality"=>"MWI",
        "FatherPin"=> "4BSBY810",
        "FatherSurname"=> "Kapundi",
        "FatherFirstName"=> "Kangaonde",
        "FatherOtherNames"=> "Masula",
        "FatherVillageId"=>-1,
        "FatherNationality"=>"MWI",
        "EbrsPk"=> nil,
        "NrisPk"=>nil,
        "PlaceOfBirthDistrictId"=>-1,
        "PlaceOfBirthDistrictName" => "Lilongwe",
        "PlaceOfBirthTAName" => "Chadza",
        "PlaceOfBirthVillageName" => "Maluwa",
        "PlaceOfBirthVillageId"=>-1,
        "MotherDistrictId"=>-1,
        "MotherDistrictName"=> "Lilongwe",
        "MotherTAName"=> "Chadza",
        "MotherVillageName"=> "Kaphantengo",
        "MotherVillageId"=>-1,
        "FatherDistrictId"=> -1,
        "FatherDistrictName"=> "Lilongwe",
        "FatherTAName" => "Chadza",
        "FatherVillageName" => "Masula",
        "EditUser"=> "Dataman1",
        "EditMachine"=>"192.168.43.5",
        "BirthCertificateNumber"=> "00000200001",
        "DistrictOfRegistration" => "Lilongwe",
        "MotherAge" => "30",
        "FatherAge" => "30",
        "DateRegistered" => "02/11/2017"
        "Category" => ""
    }]
=end

  district = Location.find(SETTINGS['location_id'])
  district_name = district.name
  district_code = district.code
  puts "DISTRICT: #{district_name}, CODE: #{district_code}"

  if district_code.blank?
    raise "Missing District Code".inspect
  end

  last_2017_ben = ActiveRecord::Base.connection.execute <<EOF
    SELECT MAX(district_id_number) ben FROM person_birth_details WHERE district_id_number LIKE '#{district_code}/%2017';
EOF
  last_2017_ben =  last_2017_ben.first[0]
  $counter = last_2017_ben.split("/")[1].to_i
#  $counter = "9884"
  puts "Last BEN: #{$counter}"

  columns = ActiveRecord::Base.connection.execute <<EOF
    SHOW columns FROM mass_data;
EOF

  columns = columns.collect{|c| c[0]}

=begin
  data = ActiveRecord::Base.connection.execute <<EOF
    SELECT * FROM mass_data WHERE
      DistrictOfRegistration = 'Lilongwe' AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
EOF

=end


  data = ActiveRecord::Base.connection.execute <<EOF
     SELECT * FROM mass_data
  WHERE
  AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
  AND DistrictOfRegistration IN ('Lilongwe', 'Lilongwe City');
EOF

=begin
  ActiveRecord::Base.connection.execute <<EOF
    UPDATE mass_data SET load_status = NULL WHERE DistrictOfRegistration = '#{district_name}'
      AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
EOF
=end

  data.each_with_index do |nid_child, index|

    hash = {}
    nid_child.each_with_index do |value, i|
      value = (value.to_s.split.map(&:capitalize).join(' ') rescue value) unless ["FathePin", "MotherPin", "DateOfBirthString"].include?(columns[i])
      hash[columns[i]] = value
    end


    ActiveRecord::Base.transaction do
      hash = hash.with_indifferent_access

      person_id = PersonService.create_nris_person(hash)
      person = format_person(hash, person_id)
      load_status = "Success"

      #Filter for Complete Cases
      if load_status == "Success"
        if ([person["Surname"], person["FirstName"], person["DateOfBirthString"], person["Nationality"],
         person["MotherSurname"], person["MotherFirstName"], person["MotherPin"], person["MotherNationality"]] & ["", nil]).length > 0
          load_status = "Record Incomplete"
        end
      end

      #Filter For Other Country

      if load_status == "Success"
          if [person["PlaceOfBirthDistrictName"], person["PlaceOfBirthTaName"], person["PlaceOfBirthVillageName"],
          person[" MotherDistrictName"], person[" MotherTAName"], person[" MotherVillageName"],
          person[" FatherDistrictName"], person[" FatherTAName"], person[" FatherVillageName"]].include("Other Country")
            load_status = "Other Country Found"
          end
      end

      #Filter For Missing District
      if load_status == "Success"
        [person["PlaceOfBirthDistrictName"], person[" MotherDistrictName"], person[" FatherDistrictName"]].each do |district|

          found = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{district}' AND tm.location_tag_id = #{$district_tag_id}
              ").length > 0

          if found == false
            load_status = "Missing District"
            break;
          end
        end
      end

      #Filter For Missing TA
      if load_status == "Success"
        [[person["PlaceOfBirthTAName"], person["PlaceOfBirthDistrictName"]],
         [person[" MotherTAName"], person["MotherDistrictName"]],
         [person[" FatherTAName"], person["FatherDistrictName"]]].each do |ta, district|
          district_id = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{district}' AND tm.location_tag_id = #{$district_tag_id}
                                                     ").first.location_id rescue nil
          found = (Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{ta}' AND tm.location_tag_id = #{$ta_tag_id} AND l.parent_location = #{district_id}
                                       ").length > 0)

          if found == false
            load_status = "Missing TA"
            break;
          end
        end
      end

      #Filter For Missing Village
      if load_status == "Success"
        [[person["PlaceOfBirthVillageName"], person["PlaceOfBirthTAName"], person["PlaceOfBirthDistrictName"]],
         [person[" MotherVillageName"], person[" MotherTAName"], person["MotherDistrictName"]],
         [person[" FatherVillageName"], person[" FatherTAName"], person["FatherDistrictName"]]].each do |village, ta, district|
          district_id = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{district}' AND tm.location_tag_id = #{$district_tag_id}
                                             ").first.location_id rescue nil
          ta_id = Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{ta}' AND tm.location_tag_id = #{$ta_tag_id} AND l.parent_location = #{district_id}
                                        ").first.location_id

          found = (Location.find_by_sql("
                    SELECT * FROM location l INNER JOIN location_tag_map tm ON l.location_id = tm.location_id
                      WHERE  l.name = '#{village}' AND tm.location_tag_id = #{$village_tag_id} AND l.parent_location = #{ta_id}
                                        ").length > 0)

          if found == false
            load_status = "Missing TA"
            break;
          end
        end
      end

      puts "#{(index + 1)} # #{load_status}"
      next
      puts "Proceeding"

      #Filter for Existing mother
      #Filter for Existing father

      status = "HQ-CAN-PRINT"

      #Filter Potential Duplicates
      duplicates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])

      #Filter Exact Duplicates
      exact_duplicates = SimpleElasticSearch.query_duplicate_coded(person, 100)
      if exact_duplicates.present?
        load_status = "Exact Duplicate(s) Found"
        status = "HQ-EXACT-DUPLICATE"
      elsif duplicates.present?
        load_status = "Potential Duplicate(s) Found"
        status = "HQ-POTENTIAL-DUPLICATE"
      end

      #Assign Birth Entry Number - BEN
      ben = assign_next_ben(person_id, district_code)

      #Assign Birth Registration Number - BRN
      brn = assign_next_brn(person_id)
      puts "#{person_id} # #{ben } # #{brn}"

      #Initialize record status
      s = PersonRecordStatus.new
      s.person_id = person_id
      s.voided = 0
      s.status_id = Status.where(name: status).first.id
      s.comment = "New Record From Mass Data"
      s.creator = $user_id
      s.save

      SimpleElasticSearch.add(person)

      ActiveRecord::Base.connection.execute <<EOF
    UPDATE mass_data SET load_status = '#{load_status}' WHERE AND id = #{nid_child[0]}
EOF

    end
  end
end

puts "Mass Data Import Starting"
mass_data
