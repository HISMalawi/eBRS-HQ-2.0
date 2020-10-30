district_tag_id  = LocationTag.where(name: "District")
tag_maps         = LocationTagMap.where(location_tag_id: district_tag_id)

list = []
year = ARGV[0]

tag_maps.each {|tm|
  district = Location.find(tm.location_id)

  available_bens = PersonBirthDetail.where(" district_id_number LIKE '#{district.code}/%/#{year}' ").collect{|ben|
      ben.district_id_number.split("/")[1].to_i
    }

  expected_range = Array(1 .. available_bens.sort.last)

  missing = (expected_range - available_bens).collect{|bn|
      "#{district.code}/#{bn.to_s.rjust(8,'0')}/#{year}"
    }

  list += missing
}

File.open("SKIPPED-BENS-#{year}.csv", "w"){|f| f.write(list.join("\n"))}