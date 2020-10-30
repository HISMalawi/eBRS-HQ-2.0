#This script restores missing date_created
#This field was missed during data migration
#Written by: Kenneth Kapundi
#Date: 22 February, 2019

births = PersonBirthDetail.where(" LENGTH(source_id) > 19 ")
puts births.count

births.each_with_index do |birth, i|

  remote_data = JSON.parse(`curl --silent http://192.168.48.2:5900/ebrs_hq/#{birth.source_id}`) rescue (puts "Missing for #{birth.source_id}")
  date        = remote_data['created_at'].to_datetime rescue nil

  puts date
end

