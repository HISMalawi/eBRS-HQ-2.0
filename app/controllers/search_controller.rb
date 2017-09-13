class SearchController < ApplicationController

  def general_search
    tag_id = LocationTag.where(name: 'District').last.id
    @districts = Location.joins(" join location_tag_map m ON m.location_id = location.location_id ")
    .where(" m.location_tag_id = #{tag_id} ").order("name")
  end

  def search_cases
    data = PersonService.search_results(params[:filter])
    render :text => data.to_json
  end
end
