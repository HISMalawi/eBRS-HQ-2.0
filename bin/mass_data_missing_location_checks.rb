require "csv"

district_tag_id = LocationTag.where(name: "District").first.id
ta_tag_id = LocationTag.where(name: "Traditional Authority").first.id
village_tag_id = LocationTag.where(name: "Village").first.id

all_districts = ActiveRecord::Base.connection.select_all("SELECT name FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
                      AND m.location_tag_id  = #{district_tag_id}
    ").collect{|b| b["name"]}


missing_districts = ActiveRecord::Base.connection.select_all("SELECT FatherDistrictName FROM mass_data WHERE FatherDistrictName NOT IN
      (SELECT l.name FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id  = #{district_tag_id} )
    ").collect{|b| b["FatherDistrictName"]}

missing_tas = []
missing_villages = []
all_districts.each_with_index do |district_name, i|
  d_name = district_name
  d_name = "NKHOTA-KOTA" if district_name.upcase.strip == "NKHOTAKOTA"
  district_id = Location.locate_id_by_tag(district_name, "District")

  ActiveRecord::Base.connection.select_all("SELECT FatherTaName FROM mass_data
          WHERE FatherDistrictName = '#{d_name}' AND FatherTaName NOT IN
          (SELECT l.name FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
              AND m.location_tag_id  = #{ta_tag_id} AND l.parent_location = #{district_id})
    ").each{|ta|

      missing_tas << "#{district_name}, #{ta["FatherTaName"]}"
  }

  district_tas = ActiveRecord::Base.connection.select_all("SELECT name FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
                      AND m.location_tag_id  = #{ta_tag_id} AND l.parent_location = #{district_id}
                  ").collect{|b| b["name"]}

  district_tas.uniq.each{|ta|
   ta_id = Location.locate_id_by_tag(ta.strip, "Traditional Authority")
    ActiveRecord::Base.connection.select_all("SELECT FatherVillageName FROM mass_data
          WHERE FatherDistrictName = '#{district_name}' AND FatherTaName = \"#{ta.strip}\" AND FatherVillageName NOT IN
          (SELECT l.name FROM location l INNER JOIN location_tag_map m ON l.location_id = m.location_id
              AND m.location_tag_id  = #{village_tag_id} AND l.parent_location = #{ta_id})
    ").each{|vg|

      missing_villages << "#{district_name}, #{ta}, #{vg["FatherVillageName"]}"
    }

  }

  puts (i + 1)

end

File.open("father-missing_districts-#{missing_districts.count}_records.csv", "w"){|f|
 f.write(missing_districts.uniq.join("\n"))
}

File.open("father-missing_ta-#{missing_tas.count}_records.csv", "w"){|f|
  f.write(missing_tas.uniq.join("\n"))
}


File.open("father-missing_villages-#{missing_villages.count}_records.csv", "w"){|f|
  f.write(missing_villages.uniq.join("\n"))
}

puts "Done!!"
