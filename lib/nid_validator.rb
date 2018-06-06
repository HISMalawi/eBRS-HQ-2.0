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
    mother_name = PersonService.mother(person.person_id)
    mother_person = Person.where(person_id: mother_name.person_id).first
    mother_address = PersonAddress.where(person_id: mother_person.person_id).first

    local_data = {
        "FirstName"         => name.first_name,
        "Surname"           => name.last_name,
        "DateOfBirthString" => person.birthdate.to_date.strftime("%d/%m/%Y"),
        "Sex"               => {"M" => 1, "F" => 2}[person.gender],
        "MotherSurname"     => mother_person.last_name,
        "MotherFirstName"   => mother_person.first_name,
        "MotherDistrictName" => Location.find(mother_address.home_district).name,
        "MotherTaName"       => Location.find(mother_address.home_ta).name,
        "MotherVillageName"  => Location.find(mother_address.home_village).name
    }

    get_url = SETTINGS['query_by_nid_address']
    RestClient.post(get_url, national_id.to_json, :content_type => 'application/json', :accept => 'json'){|request, response, result|

      data = JSON.parse(response)

      local_data.each do |key, value|

        if data[key].upcase.squish != local_data[key].upcase.squish
          mismatch[key] = {
              remote: data[key], local: local_data[key]
          }
        end
      end
    }

    mismatch
  end
end
