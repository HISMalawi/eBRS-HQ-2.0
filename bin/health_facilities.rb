facility_tag_id = LocationTag.where(name: 'Health Facility').first.id rescue [-1]
csv = "District | Health Facility\n"
(Location.find_by_sql("SELECT l2.name AS district_name, l.name AS health_facility FROM location l
                            INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id = #{facility_tag_id}
														INNER JOIN location l2 ON l2.location_id = l.parent_location
                          GROUP BY l2.location_id, l.location_id") || []).each {|l|
      csv += "#{l.district_name}|#{l.health_facility}\n"
}

File.open("#{Rails.root}/cvrs_health_facilities.csv", "w"){|f| f.write(csv)}
