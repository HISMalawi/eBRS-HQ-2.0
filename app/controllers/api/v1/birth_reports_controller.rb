class Api::V1::BirthReportsController < Api::V1::ApiController

  def index

    # TODO: Make dynamic once filter feature is added in CRVS Visio
    start_date = '01-01-2019'
    end_date = '20-01-2019'
    
    results = {}

    district_tag_id = LocationTag.where(name: "District").first.id
    facility_tag_id = LocationTag.where(name: "Health Facility").first.id

    districts = LocationTagMap.find_by_sql(" SELECT m.location_id FROM location_tag_map m
                  INNER JOIN location l ON l.location_id = m.location_id AND l.parent_location IS NULL
                  WHERE m.location_tag_id = #{district_tag_id}").map(&:location_id)
    districts.each do |district_id|
      facilities = districts = LocationTagMap.find_by_sql(" SELECT m.location_id FROM location_tag_map m
                  INNER JOIN location l ON l.location_id = m.location_id AND l.parent_location = #{district_id}
                  WHERE m.location_tag_id = #{facility_tag_id}").map(&:location_id)

      all_district_locs = facilities + [district_id]
      district = Location.find(district_id).name
      results[district] = {}
      results[district]["facility_registered"]  = registered(start_date, end_date, facilities)
      results[district]["dro_registered"] = registered(start_date, end_date, [district_id])
      # results[district]["printed"]  = Report.printed(start_date, end_date, all_district_locs)
      results[district]["total_registered"]  = registered(start_date, end_date, all_district_locs)
      #
      results[district]["cum_facility_registered"]  = registered("01-01-2000".to_date, end_date, facilities)
      results[district]["cum_dro_registered"] = registered("01-01-2000".to_date, end_date, [district_id])
      # results[district]["cum_printed"]  = Report.printed("01-01-2000".to_date, end_date, all_district_locs)
      results[district]["cum_total_registered"]  = registered("01-01-2000".to_date, end_date, all_district_locs)
      #
      # results[district]["registered_but_born_in_hospital"]  = Report.by_place_of_birth(start_date, end_date, "Hospital", all_district_locs)
      # results[district]["registered_but_born_in_home"]  = Report.by_place_of_birth(start_date, end_date, 'Home', all_district_locs)
      # results[district]["registered_but_born_in_other"]  = Report.by_place_of_birth(start_date, end_date, 'Other', all_district_locs)
      #
      # results[district]["cum_registered_but_born_in_hospital"]  = Report.by_place_of_birth("01-01-2000".to_date, end_date, "Hospital", all_district_locs)
      # results[district]["cum_registered_but_born_in_home"]  = Report.by_place_of_birth("01-01-2000".to_date, end_date, 'Home', all_district_locs)
      # results[district]["cum_registered_but_born_in_other"]  = Report.by_place_of_birth("01-01-2000".to_date, end_date, 'Other', all_district_locs)

    end

    render :json => results
  end

  private

  def registered(start_date, end_date, location_ids=[])
    PersonBirthDetail.where(" DATE(date_registered) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
      AND (source_id IS NULL OR LENGTH(source_id) >  19) AND location_created_at IN (#{location_ids.join(', ')}) ").count
  end

end
