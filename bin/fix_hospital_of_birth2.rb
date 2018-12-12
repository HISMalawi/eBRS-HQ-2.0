all_faulty = PersonBirthDetail.find_by_sql("
  SELECT * FROM person_birth_details d
  INNER JOIN location l ON l.location_id = d.district_of_birth
  WHERE d.district_of_birth = d.birth_location_id order by d.district_of_birth
  ")

puts "#{all_faulty.count} Records Found!!"
other_id = Location.where(name: "Other").first.id
csv = "person_id | BEN | place_of_birth | actual_place_of_birth\n"
all_faulty.each do |record|

  next if record.source_id.blank?
  remote_data = JSON.parse(`curl http://192.168.48.2:5900/ebrsmig/#{record.source_id}`)
  next if remote_data['_id'].blank?

  place_of_birth = remote_data["place_of_birth"].downcase

  if place_of_birth == "hospital"
    actual_place = remote_data["hospital_of_birth"]
  elsif place_of_birth == "home"
    actual_place = remote_data["birth_village"] + ", " + remote_data["birth_ta"] + ", " + remote_data["birth_district"]
  else
    actual_place = remote_data["other_birth_place_details"]
  end

  csv += "#{record.person_id}|#{record.district_id_number}|#{place_of_birth}|#{actual_place}\n"
  puts "#{record.person_id}##{record.district_id_number}"

  record.birth_location_id    = other_id
  record.other_birth_location = actual_place
  record.save
end

File.open("faulty_place_of_birth_from_migration", "w"){|f| f.write(csv)}