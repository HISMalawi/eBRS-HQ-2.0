class SearchController < ApplicationController

  def general_search
    tag_id = LocationTag.where(name: 'District').last.id
    @districts = Location.joins(" join location_tag_map m ON m.location_id = location.location_id ")
    .where(" m.location_tag_id = #{tag_id} ").order("name")
  end

  def search_cases

    filters = params[:filter].delete_if{|k, v| v.blank?}
    filters.delete(:names) if (filters[:names][:last_name].blank? && filters[:names][:middle_name].blank? && filters[:names][:first_name].blank?)

    if filters.keys.length > 1
      data = PersonService.search_results(params)
    else
      case filters.keys.first
        when 'ben'
          data = PersonService.by_ben(params, filters['ben'])
        when 'brn'
          data = PersonService.by_brn(params, filters['brn'])
        when 'names'
          data = PersonService.by_names(params, filters['names'])
        else
          data = PersonService.search_results(params)
      end
    end

    render :text => data.to_json and return
  end
end
