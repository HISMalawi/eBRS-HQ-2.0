class NIDValidator

  def self.validate(person, national_id)

=begin
    {"Surname"=>"MKAMBANKHANI",
 "OtherNames"=>"",
 "FirstName"=>"EMMANUEL",
 "DateOfBirthString"=>"27/09/1990",
 "Sex"=>1,
 "Nationality"=>"MWI",
 "Nationality2"=>"MWI",
 "Status"=>0,
 "MotherPin"=>"",
 "MotherSurname"=>"MKAMBANKHANI",
 "MotherMaidenName"=>"NAMONDWE",
 "MotherFirstName"=>"MARY",
 "MotherOtherNames"=>"",
 "MotherVillageId"=>21993,
 "MotherNationality"=>"MWI",
 "FatherPin"=>"",
 "FatherSurname"=>"MKAMBANKHANI",
 "FatherFirstName"=>"SAMUEL",
 "FatherOtherNames"=>"",
 "FatherVillageId"=>21993,
 "FatherNationality"=>"MWI",
 "EbrsPk"=>"",
 "NrisPk"=>"53513",
 "PlaceOfBirthDistrictId"=>5,
 "PlaceOfBirthVillageId"=>9937,
 "MotherDistrictId"=>18,
 "FatherDistrictId"=>18,
 "EditUser"=>"",
 "EditMachine"=>"LOCAL",
 "BirthCertificateNumber"=>"",
 "PlaceOfBirthVillageName"=>"K.C.H. STAFF LINES",
 "PlaceOfBirthTaName"=>"AREA 33",
 "PlaceOfBirthDistrictName"=>"LILONGWE CITY",
 "MotherVillageName"=>"KAPILE",
 "MotherTaName"=>"NSAMALA",
 "MotherDistrictName"=>"BALAKA",
 "FatherVillageName"=>"KAPILE",
 "FatherTaName"=>"NSAMALA",
 "FatherDistrictName"=>"BALAKA",
 "MotherAge"=>0,
 "FatherAge"=>0,
 "DateOfRegistrationString"=>"09/05/2017",
 "InformantPin"=>"",
 "InformantSurname"=>"",
 "InformantFirstName"=>"",
 "InformantOtherNames"=>"",
 "InformantNationality"=>"",
 "InformantDistrictId"=>-1,
 "InformantDistrictName"=>"",
 "InformantTAName"=>"",
 "InformantVillageName"=>"",
 "InformantPhoneNumber"=>"",
 "InformantAddress"=>""}
=end
    mismatch = {}
    name = PersonName.where(person_id: person.person_id).first
    details = PersonBirthDetail.where(person_id: person.person_id).first

    mother_name = PersonService.mother(person.person_id)
    mother_person = Person.where(person_id: mother_name.person_id).first
    mother_address = PersonAddress.where(person_id: mother_person.person_id).first

    father_name = PersonService.father(person.person_id) rescue nil
    father_person = Person.where(person_id: father_name.person_id).first rescue nil
    father_address = PersonAddress.where(person_id: father_person.person_id).first rescue nil

    codes = JSON.parse(File.read("#{Rails.root}/db/code2country.json"))

    local_data = {
        "FirstName"                => name.first_name,
        "Surname"                  => name.last_name,
        "DateOfBirthString"        => person.birthdate.to_date.strftime("%d/%m/%Y"),
        "Sex"                      => {"M" => 1, "F" => 2}[person.gender],
        "PlaceOfBirthDistrictName" => (Location.find(details.district_of_birth).name rescue nil),
        "MotherSurname"            => mother_person.last_name,
        "MotherFirstName"          => mother_person.first_name,
        "MotherOtherNames"         => mother_person.middle_name,
        "MotherDistrictName"       => (Location.find(mother_address.home_district).name rescue ""),
        "MotherTaName"             => (Location.find(mother_address.home_ta).name rescue ""),
        "MotherVillageName"        => (Location.find(mother_address.home_village).name rescue ""),
        "MotherNationality"        => (Location.find(mother_address.citizenship).name rescue "")
    }

    if !father_name.blank?
      local_data["FatherSurname"]       = father_name.last_name
      local_data["FatherFirstName"]     = father_name.first_name
      local_data["FatherOtherNames"]    = father_name.middle_name
      local_data["FatherDistrictName"]  = (Location.find(father_address.home_district).name rescue ""),
      local_data["FatherTaName"]        = (Location.find(father_address.home_ta).name rescue ""),
      local_data["FatherVillageName"]   = (Location.find(father_address.home_village).name rescue ""),
      local_data["FatherNationality"]   = (Location.find(father_address.citizenship).name rescue "")
    end

    get_url = SETTINGS['query_by_nid_address']
    passed = 0

    begin
      RestClient.post(get_url, national_id.to_json, :content_type => 'application/json', :accept => 'json'){|response, request, result|

        data = JSON.parse(response)

        if data.present?
          data["MotherNationality"] = codes[data["MotherNationality"]]
          if !data["FatherNationality"].blank?
            data["FatherNationality"] = codes[data["FatherNationality"]]
          end

          local_data.each do |key, value|

            if data[key].to_s.upcase.squish != local_data[key].to_s.upcase.squish
              mismatch[key] = {
                remote: data[key], local: local_data[key]
              }
            end
          end

          if mismatch.blank?
            passed = 1
          end
        end
      }
    rescue
    end

    record = NidVerificationData.new
    record.person_id = person.person_id
    record.passed    = passed
    record.data      = mismatch.to_json
    record.save

    mismatch
  end
end
