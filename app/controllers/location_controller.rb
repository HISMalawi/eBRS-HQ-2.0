class LocationController < ApplicationController
  def sites
  end

  def get_location
    location = []
    from  = params[:record_limit].to_i
    to    = (from + 99)

    location_tag = LocationTag.find(params[:location_tag_id])

    locations = Location.group("location.location_id").where("t.location_tag_id = ?",
      location_tag.id).joins("INNER JOIN location_tag_map m 
      ON m.location_id = location.location_id
      INNER JOIN location_tag t 
      ON t.location_tag_id = m.location_tag_id").limit("#{from}, #{to}").order("location.name ASC")

    (locations || []).each do |l|
      if location_tag.name == 'Village'
        ta = Location.find(l.parent_location)
        district = Location.find(ta.parent_location).name
        location << {
          location_id:  l.id,
          name:         l.name,
          ta:           ta.name,
          district:     district
        } 
      end

      location << {
        location_id:  l.id,
        name:         l.name,
        description:  l.description,
        code:         l.code
      } if location_tag.name == 'District'

      if location_tag.name == 'Traditional Authority'
        district = Location.find(l.parent_location).name
        location << {
          location_id:  l.id,
          name:         l.name,
          district:     district,
          location_id:  l.id
        } 
      end

      if location_tag.name == 'Health Facility'
        district = Location.find(ta.parent_location).name
        location << {
          location_id:  l.id,
          name:         l.name,
          description:  l.description,
          latitude:     l.latitude,
          longitude:    l.longitude,
          code:         l.code,
          postal_code:  l.postal_code,
          district:     district
        } 
      end

    end
    render text: location.to_json and return
  end

  def tag
  end

end
