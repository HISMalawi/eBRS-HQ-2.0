csv = "DISTRICT-CODE, TOTAL-REGISTERED\n"
all = PersonBirthDetail.find_by_sql("SELECT SUBSTRING(district_id_number, 1, 3) code, COUNT(*) total FROM person_birth_details
              WHERE district_id_number LIKE '%/2018' GROUP BY SUBSTRING(district_id_number, 1, 3)").as_json
all.each do |line|
  csv += "#{line['code']},#{line['total']}\n"
end

File.open("csv.csv", "w"){|f|
  f.write(csv);
}