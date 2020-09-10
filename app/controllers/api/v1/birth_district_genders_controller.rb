class Api::V1::BirthDistrictGendersController < Api::V1::ApiController

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
      results[district]["female"]  = female(start_date, end_date, [district_id])
      results[district]["male"] = male(start_date, end_date, [district_id])

    end

    render :json => results
  end

  private

  def female(start_date, end_date, location_ids=[])
    start_date = start_date.to_date.to_s rescue Date.today.to_s
    end_date = end_date.to_date.to_s rescue Date.today.to_s

    status_ids = Status.all.map{|m| m.status_id}.join(",")

    locations = location_ids

    query = "SELECT COUNT(*) AS total FROM person_birth_details pbd
INNER JOIN person p ON p.person_id = pbd.person_id
INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
    GROUP BY p.gender"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

  def male(start_date, end_date, location_ids=[])
    start_date = start_date.to_date.to_s rescue Date.today.to_s
    end_date = end_date.to_date.to_s rescue Date.today.to_s

    status_ids = Status.all.map{|m| m.status_id}.join(",")

    # if params[:district].present?
    #   locations = Location.find(params[:district]).children << Location.find(params[:district]).id
    # else
    #   locations = []
    # end

    locations = location_ids

    query = "SELECT COUNT(*) AS total FROM person_birth_details pbd
INNER JOIN person p ON p.person_id = pbd.person_id
INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
    GROUP BY p.gender"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

end
