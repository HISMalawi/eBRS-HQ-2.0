$codes = JSON.parse(File.read("#{Rails.root}/db/code2country.json"))

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

columns = ActiveRecord::Base.connection.execute <<EOF
    SHOW columns FROM mass_data;
EOF

columns = columns.collect{|c| c[0]}
$exact_duplicates       = []
$exact_duplicates << columns.join(",")
$potential_duplicates       = []
$potential_duplicates << columns.join(",")

exact_duplicates = ActiveRecord::Base.connection.execute <<EOF
    SELECT * FROM mass_data WHERE load_status = 'Exact Duplicate(s) Found'
EOF
potential_duplicates = ActiveRecord::Base.connection.execute <<EOF
    SELECT * FROM mass_data WHERE load_status = 'Potential Duplicate(s) Found'
EOF


exact_duplicates.each do |record|
  hash = {}
  record.each_with_index do |value, i|
    value = (value.to_s.split.map(&:capitalize).join(' ') rescue value) unless ["FathePin", "MotherPin", "DateOfBirthString"].include?(columns[i])
    hash[columns[i]] = value
  end

  person = format_person(hash, 0)
  query_results = SimpleElasticSearch.query_duplicate_coded(person, 100)

  line = record.join(",") + ","
  query_results.each do |result|
    person_id = result['_id']
    detail = PersonBirthDetail.where(source_id: person_id).first
    name   = PersonName.where(person_id: person_id).first
    $exact_duplicates << detail.district_id_number
    line += "#{detail.district_id_number}|#{name.last_name}|#{name.first_name}|#{name.middle_name}"

  end
  $exact_duplicates << line

end

File.open("Exact_duplicates.csv", "w"){|f| f.write($exact_duplicates.join("\n"))}


potential_duplicates.each do |record|

  line = record.join(",") + ","
  detail = PersonBirthDetail.where(source_id: record[0]).first
  potential_duplicate = PotentialDuplicate.where(person_id: detail.person_id).first
  query_results = DuplicateRecord.where(potential_duplicate_id: potential_duplicate.id) rescue []
  puts "#{query_results.count} Found!"
  query_results.each do |result|
    person_id = result.person_id
    detail2 = PersonBirthDetail.where(person_id: person_id).first
    name   = PersonName.where(person_id: person_id).first
    $potential_duplicates << detail2.district_id_number
    line += "#{detail2.district_id_number}|#{name.last_name}|#{name.first_name}|#{name.middle_name}"
  end
  $potential_duplicates << line

end

File.open("Potential_duplicates.csv", "w"){|f| f.write($potential_duplicates.join("\n"))}






