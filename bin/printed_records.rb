csv = "DISTRICT-CODE, TOTAL-PRINTED\n"
admin_roles = Role.where(role: "Administrator").pluck :role_id
all = PersonBirthDetail.find_by_sql("SELECT SUBSTRING(district_id_number, 1, 3) code, COUNT(*) total FROM person_birth_details
              INNER JOIN person_record_statuses prs ON prs.status_id IN (39, 62) AND prs.person_id = person_birth_details.person_id
              INNER JOIN user_role ur ON ur.user_id = prs.creator AND ur.role_id NOT IN (#{admin_roles.join(',')})
              WHERE DATE(prs.created_at) BETWEEN '2018-01-01' AND '2018-12-31'
                GROUP BY SUBSTRING(district_id_number, 1, 3)
              ").as_json


all.each do |line|
  csv += "#{line['code']},#{line['total']}\n"
end

File.open("csv_printed.csv", "w"){|f|
  f.write(csv);
}

