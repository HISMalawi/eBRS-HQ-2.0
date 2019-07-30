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

	  	if data['data'].blank?
						#Try Remote Search
						district_code = filters['ben'].split("/")[0].strip rescue nil

						if !district_code.blank?
							location_id = Location.where(code: district_code).first.id
							ip = YAML.load_file("public/sites/#{location_id}.yml")[location_id]['ip_addresses'].first.split(":").first rescue nil
							if !ip.blank?
								person_id = RestClient.get("http://#{ip}:4000/get_person_id?ben=#{filters['ben']}").to_s rescue nil
								if !person_id.blank?
									PersonService.force_sync(person_id) 
									data = PersonService.search_results(params)
								end
							end
						end
					end
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
