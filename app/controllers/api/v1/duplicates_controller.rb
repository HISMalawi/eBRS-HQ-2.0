module Api
  module V1
    class DuplicatesController < ApiController
      # GET /duplicates
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
          results[district]  = Report.duplicates('2019-01-01','2019-01-29', all_district_locs)
          results
        end

        render :json => results
      end

      # GET /duplicates/:id
      def show; end

      # POST /duplicates
      def create; end

      # PUT /duplicates/:id
      def update; end

      # DELETE /duplicates/:id
      def destroy; end

    end
  end
end
