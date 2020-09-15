file_name =  ARGV[0]
final_file_name = ARGV[1]

header = false
ebrs_key_index = -1
brn_index = -1
nid_index = -1

data = File.read(file_name).split("\n")
count = data.length

data.each_with_index do |line, i|

  data = line.split("|")
	
  if header == false
    ebrs_key_index    = data.index("eBRS Primary Key")
	  data << "BRN"
    data << "National ID"

		brn_index =   data.index("BRN")
		nid_index =   data.index("National ID")

    File.open(final_file_name, "w"){|f|
      line = data.join("|") + "\n"
      f.write(line)
    }
    header = true
    next
  end

  person_id = data[ebrs_key_index]
  detail    = PersonBirthDetail.where(person_id: person_id).first
  brn 	= detail.brn rescue nil
  nid	= detail.national_id rescue nil

  data[brn_index] = brn
  data[nid_index] = nid

  File.open(final_file_name, "a"){|f|
    line = data.join("|") + "\n"
    f.write(line)
  }

	puts "#{(i + 1)} / #{count}  => # #{brn} # #{nid}"
end
