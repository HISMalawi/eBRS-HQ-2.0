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


File.open("#{"data_2018_re-extracted.csv"}", "w"){|f|
  f.write(csv)
}

i = -1
sentinel_date = "04-01-2019".to_date
print_status_ids = Status.where(" name IN ('HQ-PRINTED', 'DC-PRINTED') ").pluck :status_id
dispatch_status_ids = Status.where(" name IN ('HQ-DISPATCHED') ").pluck :status_id

CSV.foreach("#{ARGV[0]}") do |row|
  i += 1

  data = row[0].split("|")
  ben  = data[0]
  next if i == 0 #Header Row
  next if !ben.match(/2018$/)
  #Delayed Registration|Date Entered in eBRS|Date Printed|Date Dispatched
  puts "Count: #{i} # #{ben}"
  pbd               = PersonBirthDetail.where(" district_id_number = '#{ben}' ").first
  person            = Person.where(person_id: pbd.person_id).select("birthdate").first
  certificate       = Certificate.where(person_id: pbd.person_id)

  #Delayed Registration
  days_gone = ((pbd.date_reported.to_date rescue Date.today) - person.birthdate.to_date).to_i rescue 0
  delayed =  days_gone > 42 ? "Yes" : "No"

  #Date Entered in eBRS
  date_created = pbd.created_at.to_date.to_s

  #Date Printed

  date_printed     = certificate.date_printed.to_date rescue nil
  date_printed     = PersonRecordStatus.where(" person_id = #{pbd.person_id} AND status_id IN (#{print_status_ids.join(',')}) ")
                      .order(" created_at ").first.created_at.to_date rescue nil if date_printed.blank?
  date_dispatched  = PersonRecordStatus.where(" person_id = #{pbd.person_id} AND status_id IN (#{dispatch_status_ids.join(',')}) ")
                      .order(" created_at ").first.created_at.to_date rescue nil if date_dispatched.blank?

  if certificate.blank? || (date_printed && date_printed > sentinel_date)
    date_printed    = nil
    date_dispatched = nil
  else
    date_dispatched  = certificate.date_dispatched.to_date rescue nil
  end

  data << delayed
  data << date_created
  data << date_printed
  data << date_dispatched

  File.open("#{"data_2018_re-extracted.csv"}", "a"){|f|
    line = data.join("|") + "\n"
    f.write(line)
  }

end

