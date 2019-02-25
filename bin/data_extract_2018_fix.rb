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
csv                += "Informant Phone Number|Informant Address|Informant Relationship|Date Reported|Date Registered|"
csv                += "Delayed Registration|Date Entered in eBRS|Date Printed|Date Dispatched\n"
pos = csv.split("|").index("Date Entered in eBRS")
pos_2 = csv.split("|").index("Date Registered")

File.open("#{"data_2018_with_extra_fields2.csv"}", "w"){|f|
  f.write(csv)
}

i = -1
CSV.foreach("#{ARGV[0]}") do |row|
  i += 1

  data = row[0].split("|")
  ben  = data[0]
  next if i == 0 #Header Row

  pbd           = PersonBirthDetail.where(" district_id_number = '#{ben}' ").first
  date_created  =  pbd.created_at.to_date.to_s
  puts "#{pbd.person_id} -- #{date_created}"

  if data[pos_2] == "Yes"
    #Column shift
    data.insert(pos_2, "")
  end
  data.insert(pos, date_created)

  File.open("#{"data_2018_with_extra_fields2.csv"}", "a"){|f|
    line = data.join("|") + "\n"
    f.write(line)
  }


end

