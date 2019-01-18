require "csv"

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

File.open("#{"data_2018.csv"}", "a"){|f|
  f.write(csv)
}

CSV.foreach("#{ARGV[0]}") do |row|

  data = row[0].split("|")
  ben  = data[0]
  next if !data[0].match("/2018")
  next if ben.blank?

  pbd  = PersonBirthDetail.where(" district_id_number = '#{ben}' AND ( source_id IS NULL OR LENGTH(source_id) > 30 ) ").select(" source_id ").first
  puts "#{pbd.source_id}##{ben}"

  File.open("#{"data_2018.csv"}", "a"){|f|
    line = data.join("|") + "\n"
    f.write(line)
  }

end

