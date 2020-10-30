#This file is used to sync data birectional from and to all enabled sites
#Kenneth Kapundi@25/Oct/2017

file_name = "locations.csv"
district_tag = LocationTag.where(name: 'District').first
ta_tag = LocationTag.where(name: 'Traditional Authority').first
village_tag   = LocationTag.where(name: 'Village').first
data = "District | TA | Village\n"
LocationTagMap.where(location_tag_id: district_tag.id).each_with_index {|district, i|
  tas = Location.find_by_sql(" SELECT * FROM location l
                                INNER JOIN location_tag_map m ON l.location_id = m.location_id
                                WHERE l.parent_location = #{district.location_id} AND m.location_tag_id = #{ta_tag.id}").map(&:location_id)
  district_name = Location.find(district.location_id).name
  tas.each { |ta_id|
    ta = Location.find(ta_id)
    ta_name = ta.name
    villages = Location.find_by_sql(" SELECT l.name FROM location l
                                INNER JOIN location_tag_map m ON l.location_id = m.location_id
                                WHERE l.parent_location = #{ta.location_id} AND m.location_tag_id = #{village_tag.id}").map(&:name)
    villages.each { |village_name|
      data += "#{district_name} | #{ta_name} | #{village_name} \n"
    }
  }

  puts "#{i + 1} district(s)"
}

File.open("#{file_name}", "w"){|f| f.write(data)}