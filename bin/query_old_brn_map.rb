puts "Running script to fix BRN's"
old_brn_type_id = PersonIdentifierType.where(name: "Old Birth Registration Number").first.id
old_ben_type_id = PersonIdentifierType.where(name: "Old Birth Entry Number").first.id

data = PersonIdentifier.find_by_sql("
SELECT p.person_id, p.value old_ben, SUBSTRING(p.value, 1, 5) lef, SUBSTRING(p.value, 6, 1) gender, SUBSTRING(p.value, -5, 5) righ,
  d.district_id_number new_ben, d.national_serial_number, p2.value old_brn, pn.first_name, pn.last_name, pn.middle_name, ps.gender sex, ps.birthdate
FROM person_identifiers p
  INNER JOIN person_birth_details d ON d.person_id = p.person_id
  INNER JOIN person ps ON ps.person_id = p.person_id
  INNER JOIN person_name pn ON pn.person_id = p.person_id
  INNER JOIN person_identifiers p2 ON p2.person_id = p.person_id AND p2.person_identifier_type_id = #{old_brn_type_id}
	WHERE p.person_identifier_type_id = #{old_ben_type_id} ORDER BY lef ASC, righ ASC;
")

file_data = "Old BRN | New BRN |  Old BEN | New BEN | First Name | Middle Name | Last Name | Gender | Birthdate \n"
count = 0
total = data.length

data.each do |d|
  count = count + 1
  puts "#{count}/#{total}"

  n = d.national_serial_number
  brn = ""
  if !n.blank? || n.to_i > 0
    gender = d.sex == 'M' ? '2' : '1'
    n = n.to_s.rjust(12, '0')
    brn = (n.insert(n.length/2, gender))
  end

  file_data = file_data + "'#{d.old_brn}' | '#{brn}' | #{d.old_ben} | #{d.new_ben} | #{d.first_name} | #{d.middle_name} | #{d.last_name} | #{d.sex} | #{d.birthdate} \n"
end

File.open("fixed_mapping.csv", 'w'){|f|
  f.write(file_data)
}


