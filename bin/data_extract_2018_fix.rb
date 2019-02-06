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
csv                += "Delayed Registration|Date Printed|Date Dispatched\n"

File.open("#{"data_2018_with_extra_fields.csv"}", "a"){|f|
  f.write(csv)
}

CSV.foreach("#{ARGV[0]}") do |row|

  data = row[0].split("|")
  ben  = data[0]
  next if !data[0].match("/2018")
  next if ben.blank?

  pbd         = PersonBirthDetail.where(" district_id_number = '#{ben}' AND ( source_id IS NULL OR LENGTH(source_id) > 30 ) ").first
  puts pbd.person_id
  person      = Person.find(pbd.person_id)
  days_gone   = ((pbd.date_registered.to_date rescue Date.today) - person.birthdate.to_date).to_i rescue 0
  delayed     =  days_gone > 42 ? "Yes" : "No"
  data        << delayed

  certificate       = Certificate.where(person_id: pbd.person_id).first
  date_printed      = ''
  date_dispatched   = ''

  unless certificate.blank?
    date_printed    = certificate.date_printed
    date_dispatched = certificate.date_dispatched
  end

  data << date_printed
  data << date_dispatched

  puts "#{pbd.person_id}##{delayed}##{date_printed}##{date_dispatched}"

  File.open("#{"data_2018_with_extra_fields.csv"}", "a"){|f|
    line = data.join("|") + "\n"
    f.write(line)
  }

end

