$counter = 0
def assign_next_ben(person_id, district_code)

  $counter = $counter.to_i + 1
  mid_number = $counter.to_s.rjust(8,'0')
  ben = "#{district_code}/#{mid_number}/2017"
  ActiveRecord::Base.connection.execute <<EOF
    UPDATE person_birth_details SET district_id_number = '#{ben}' WHERE person_id = #{person_id}
EOF

  PersonIdentifier.new_identifier(person_id, 'Birth Entry Number', ben)
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
  last_2017_ben =  data = ActiveRecord::Base.connection.execute <<EOF
    SELECT MAX(district_id_number) ben FROM person_birth_details WHERE district_id_number LIKE '#{district_code}/%2017';
EOF
  last_2017_ben =  last_2017_ben.first[0]
  ben_counter = last_2017_ben.split("/")[1].to_i


  columns = ActiveRecord::Base.connection.execute <<EOF
    SHOW columns FROM mass_data;
EOF

  columns = columns.collect{|c| c[0]}
  data = ActiveRecord::Base.connection.execute <<EOF
    SELECT * FROM mass_data WHERE DistrictOfRegistration = '#{district_name}' AND category NOT IN ('BiologicalMother-Separated', 'BiologicalMother-Abandoned')
EOF

  data.each do |nid_child|

    hash = {}
    nid_child.each_with_index do |value, i|
      hash[columns[i]] = value
    end


    ActiveRecord::Base.transaction do
      person_id = PersonService.create_nris_person(nid_child)
      if !person_id.blank?
        #Assign BEN
      end
    end
  end
end

puts "Mass Data Import Starting"
mass_data
