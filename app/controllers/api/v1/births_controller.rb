module Api
  module V1
    class BirthsController < ApplicationController
      # GET /births
      def index

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
          case params[:state]
          when 'reported'
            results[district] = Report.reported('2019-01-01','2019-01-29', all_district_locs)
          when 'approved'
            results[district] = Report.approved_by_dm('2019-01-01','2019-01-29', all_district_locs)
          else
            results[district] = Report.total('2019-01-01','2019-01-29', all_district_locs)
          end

          case params[:report]
          when 'facility_registered'
            results[district] = Report.registered('2019-01-01','2019-01-29', facilities)
          when 'dro_registered'
            results[district] = Report.registered('2019-01-01','2019-01-29', [district_id])
          else
            results[district]  = Report.registered('2019-01-01','2019-01-29', all_district_locs)
          end

          case params[:cumulative]
          when 'cum_facility_registered'
            results[district] = Report.registered("01-01-2000".to_date, '2019-01-29', facilities)
          when 'cum_dro_registered'
            results[district] = Report.registered("01-01-2000".to_date, '2019-01-29', [district_id])
          else
            results[district]  = Report.registered("01-01-2000".to_date, '2019-01-29', all_district_locs)
          end

          results
        end

        render :json => results
      end

      # GET /births/:id
      def show; end

      # POST /births
      def create; end

      # PUT /births/:id
      def update; end

      # DELETE /births/:id
      def destroy; end

    end
  end
end
