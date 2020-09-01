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
      results[district]["printed"]  = printed(start_date, end_date, all_district_locs)
      results[district]["total_registered"]  = registered(start_date, end_date, all_district_locs)
      #
      results[district]["cum_facility_registered"]  = registered("01-01-2000".to_date, end_date, facilities)
      results[district]["cum_dro_registered"] = registered("01-01-2000".to_date, end_date, [district_id])
      results[district]["cum_printed"]  = printed("01-01-2000".to_date, end_date, all_district_locs)
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
    loc_query = ""
    unless location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    query = "SELECT count(*) as total FROM person_birth_details
WHERE date_registered BETWEEN '#{start_date.to_date.to_s}'
AND '#{end_date.to_date.to_s}' AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query};"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

  def printed(start_date, end_date, location_ids=[])
    loc_query = ""
    unless location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    query = "SELECT count(*) as total FROM person_birth_details d
    INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
    WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
    AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
    AND prs.status_id IN (select status_id from statuses where name IN ('DC-PRINTED', 'HQ-PRINTED', 'HQ-DISPATCHED'))"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

end
