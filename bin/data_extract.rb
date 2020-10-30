=begin
  This script is for extracting data from MYSQL to CSV for sharing with NRB
  Written By: Kenneth Kapundi
  Date: 27 Nov, 2018

  Usage: bundle exec rails runner bin/data_extract.rb destination_csv_file_name
  Example Usage: bundle exec rails runner bin/data_extract /var/www/ebrs_data.csv
=end

file_name           = ARGV[0]
raise "Missing File Name \n Usage: bundle exec rails runner bin/data_extract.rb destination_csv_file_name".to_s if file_name.blank?
error_file_name     = "#{file_name}-errored.csv"
chunk               = ARGV[1]

delivery_modes      = ModeOfDelivery.all.inject({}) { |r, d| r[d.id] = d.name; r }
education_levels    = LevelOfEducation.all.inject({}) { |r, d| r[d.id] = d.name; r }
type_of_birth       = PersonTypeOfBirth.all.inject({}) { |r, d| r[d.id] = d.name; r }
location_map        = Location.all.inject({}) { |r, d| r[d.id] = d.name; r }
status_map          = Status.all.inject({}) { |r, d| r[d.id] = d.name; r }
binary_options      = {0 => "No", 1 => "Yes"}

mother_type_id      = PersonRelationType.where(name: "Mother").first.id
ad_mother_type_id   = PersonRelationType.where(name: "Adoptive-Mother").first.id
father_type_id      = PersonRelationType.where(name: "Father").first.id
ad_father_type_id   = PersonRelationType.where(name: "Adoptive-Father").first.id
nid_type_id         = PersonIdentifierType.where(name: "National ID Number").first.id
informant_type_id   = PersonRelationType.where(name: "Informant").first.id
phone_type_id       = PersonAttributeType.where(name: "Cell Phone Number").first.id

#Build Headers
csv                 = "BEN|BRN|National ID|Record Status|Place Of Registration|"
csv                += "First Name|Middle Name|Last Name|Sex|Birthdate|Place Of Birth|District of Birth|Birth Location|"
csv                += "Mother ID Number|Mother First Name|Mother Middle Name|Mother Last Name|Mother Birthdate|Mother Citizenship|"
csv                += "Mother Home District|Mother Home TA|Mother Home Village|"
csv                += "Mother Current District|Mother Current TA|Mother Current Village|"

csv                += "Birth Weight|Type of Birth|Parents Married|Date of Marriage|Gestation at Birth|Number of Prenatal Visits|"
csv                += "Month Prenatal Care Started|Mode of Delivery|Number of Children Born Alive Inclusive|Number of Children Born Still Alive|"
csv                += "Mother Level of Education|Parents Signed|Form Signed|"

csv                += "Father ID Number|Father First Name|Father Middle Name|Father Last Name|Father Birthdate|Father Citizenship|"
csv                += "Father Home District|Father Home TA|Father Home Village|"
csv                += "Father Current District|Father Current TA|Father Current Village|"

csv                += "Informant ID Number|Informant First Name|Informant Middle Name|Informant Last Name|"
csv                += "Informant Current District|Informant Current TA|Informant Current Village|"
csv                += "Informant Phone Number|Informant Address|Informant Relationship|Date Reported|Date Registered\n"
error_csv           = ""

count               = 1

person_ids = []
if !chunk.blank?
  person_ids        = File.read(chunk).split(",")
else
  person_ids        = PersonBirthDetail.pluck :person_id
end

total_records       = person_ids.count
PersonBirthDetail.where(" person_id IN (#{person_ids.join(',')}) ").find_each{|details|

  puts "#{count}/#{total_records}##{details.person_id}"
  count +=1

  begin
    brn               = details.brn
    nid               = PersonIdentifier.where(person_id: details.person_id, person_identifier_type_id: nid_type_id).first.value rescue ""
    status_id         = PersonRecordStatus.where(person_id: details.person_id).order("created_at").last.status_id rescue ""
    csv               += "#{details.district_id_number}|#{brn}|#{nid}|#{status_map[status_id]}|#{location_map[details.location_created_at]}|"

    name              = PersonName.where(person_id: details.person_id).last
    person            = Person.find(details.person_id)
    place             = location_map[details.place_of_birth]
    district_of_birth = location_map[details.district_of_birth]

    location        = location_map[details.birth_location_id]
    if place ==  "Home" || place == "Hospital"
      location        = location_map[details.birth_location_id]
    end

    if place == "Other" || location == "Other" || location == district_of_birth
      location        = details.other_birth_location
    end

    mother_person  = PersonRelationship.where(person_a: details.person_id, person_relationship_type_id: mother_type_id).first
    if mother_person.blank?
      mother_person  = PersonRelationship.where(person_a: details.person_id, person_relationship_type_id: ad_mother_type_id).first
    end
    mother_person_id = mother_person.person_b if !mother_person.blank?

    if !mother_person_id.blank?
      mother            = Person.find(mother_person_id)
      mother_name       = PersonName.where(person_id: mother_person_id).last
      mother_address    = PersonAddress.where(person_id: mother_person_id).last
    end

    father_person  = PersonRelationship.where(person_a: details.person_id, person_relationship_type_id: father_type_id).first
    if father_person.blank?
      father_person  = PersonRelationship.where(person_a: details.person_id, person_relationship_type_id: ad_father_type_id).first
    end

    father_person_id = father_person.person_b if !father_person.blank?

    if !father_person_id.blank?
      father            = Person.find(father_person_id)
      father_name       = PersonName.where(person_id: father_person_id).last
      father_address    = PersonAddress.where(person_id: father_person_id).last
    end

    info_person  = PersonRelationship.where(person_a: details.person_id, person_relationship_type_id: informant_type_id).first
    info_person_id = info_person.person_b if !info_person.blank?

    if !info_person_id.blank?
      info            = Person.find(info_person_id)
      info_name       = PersonName.where(person_id: info_person_id).last
      info_address    = PersonAddress.where(person_id: info_person_id).last
    end

    csv              += "#{name.first_name rescue "N/A"}|#{name.middle_name rescue "N/A"}|#{name.last_name rescue "N/A"}|#{person.gender}|#{person.birthdate}|"
    csv              += "#{place}|#{district_of_birth}|#{location}|"

    if mother_person_id.blank?
      csv                += "||||||||||||"
    else
      m_citizenship       = location_map[mother_address.citizenship] rescue ""
      m_home_district     = location_map[mother_address.home_district] rescue ""
      m_home_ta           = location_map[mother_address.home_ta] rescue ""
      m_home_village      = location_map[mother_address.home_village] rescue ""

      m_cur_district      = location_map[mother_address.current_district] rescue ""
      m_cur_ta            = location_map[mother_address.current_ta] rescue ""
      m_cur_village       = location_map[mother_address.current_village] rescue ""

      m_nid               = PersonIdentifier.where(person_id: mother_person_id,
                                                   person_identifier_type_id: nid_type_id).first.value rescue ""

      csv                += "#{m_nid}|#{mother_name.first_name rescue "N/A"}|#{mother_name.middle_name rescue "N/A"}|#{mother_name.last_name rescue "N/A"}|#{mother.birthdate}|#{m_citizenship}|"
      csv                += "#{m_home_district}|#{m_home_ta}|#{m_home_village}|"
      csv                += "#{m_cur_district}|#{m_cur_ta}|#{m_cur_village}|"
    end

    csv                += "#{details.birth_weight}|#{type_of_birth[details.type_of_birth]}|#{binary_options[details.parents_married_to_each_other]}|#{details.date_of_marriage}|#{details.gestation_at_birth}|#{details.number_of_prenatal_visits}|"
    csv                += "#{details.month_prenatal_care_started}|#{delivery_modes[details.mode_of_delivery_id]}|#{details.number_of_children_born_alive_inclusive}|#{details.number_of_children_born_still_alive}|"
    csv                += "#{education_levels[details.level_of_education_id]}|#{binary_options[details.parents_signed]}|#{binary_options[details.form_signed]}|"

    if father_person_id.blank?
      csv                += "||||||||||||"
    else
      f_citizenship       = location_map[father_address.citizenship] rescue ""
      f_home_district     = location_map[father_address.home_district] rescue ""
      f_home_ta           = location_map[father_address.home_ta] rescue ""
      f_home_village      = location_map[father_address.home_village] rescue ""

      f_cur_district      = location_map[father_address.current_district] rescue ""
      f_cur_ta            = location_map[father_address.current_ta] rescue ""
      f_cur_village       = location_map[father_address.current_village] rescue ""

      f_nid               = PersonIdentifier.where(person_id: father_person_id,
                                                   person_identifier_type_id: nid_type_id).first.value rescue ""

      csv                += "#{f_nid}|#{father_name.first_name rescue "N/A"}|#{father_name.middle_name rescue "N/A"}|#{father_name.last_name rescue "N/A"}|#{father.birthdate}|#{f_citizenship}|"
      csv                += "#{f_home_district}|#{f_home_ta}|#{f_home_village}|"
      csv                += "#{f_cur_district}|#{f_cur_ta}|#{f_cur_village}|"
    end

    i_nid               = PersonIdentifier.where(person_id: info_person_id,
                                                 person_identifier_type_id: nid_type_id).first.value rescue ""

    i_cur_district      = location_map[info_address.current_district] rescue ""
    i_cur_ta            = location_map[info_address.current_ta] rescue ""
    i_cur_village       = location_map[info_address.current_village] rescue ""
    phone_number        = PersonAttribute.where(person_id: info_person_id,
                                                person_attribute_type_id: phone_type_id, voided: 0).first.value rescue ""
    i_postal_address    = "#{i_postal_address.address_line_1}, #{info_address.address_line_2}, #{info_address.city}" rescue nil

    csv                += "#{i_nid}|#{(info_name.first_name rescue nil)}|#{(info_name.middle_name rescue nil)}|#{(info_name.last_name rescue nil)}|"
    csv                += "#{i_cur_district}|#{i_cur_ta}|#{i_cur_village}|#{phone_number}|#{i_postal_address}|"
    csv                += "#{details.informant_relationship_to_person}|#{details.date_reported}|#{details.date_registered}\n"

    csv              += "\n"

  rescue
    error_csv += "#{details.person_id}\n"
  end
}

csv       = csv.force_encoding('utf-8').encode
error_csv = error_csv.force_encoding('utf-8').encode

File.open("#{file_name}", "w"){|f|
  f.write(csv)
}

File.open("#{error_file_name}", "w"){|f|
  f.write(error_csv)
}