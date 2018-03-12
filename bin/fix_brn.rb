puts "Running script to fix BRN's"
old_brn_type_id = PersonIdentifierType.where(name: "Old Birth Registration Number").first.id
data = PersonIdentifier.find_by_sql("
SELECT person_id, value, SUBSTRING(value, 1, 5) lef, SUBSTRING(value, 6, 1) gender, SUBSTRING(value, -5, 5) righ
FROM person_identifiers
	WHERE person_identifier_type_id = #{old_brn_type_id} ORDER BY lef ASC, righ ASC;
")

count = 0
data.each do |d|
  count = count + 1
<<<<<<< HEAD
  PersonBirthDetail.where(person_id: d.person_id).first.update_columns(national_serial_number: count)
end
=======
  puts count
  PersonBirthDetail.where(person_id: d.person_id).first.update_columns(national_serial_number: count)
end
>>>>>>> 4bd8ddc20931d6baca6990c9acd6300a43c372a6
