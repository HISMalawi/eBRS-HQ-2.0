class LocationController < ApplicationController
  def sites
  end

  def get_location
    location = []
    locations = Location.where("t.location_tag_id = ?",
      params[:location_tag_id]).joins("INNER JOIN location_tag_map m ON m.location_id = location.location_id
      INNER JOIN location_tag t ON t.location_tag_id = m.location_tag_id")

    (locations || []).each do |l|
      location << {
        location_id:  l.id,
        name:         l.name,
        description:  l.description,
        latitude:     l.latitude,
        longitude:    l.longitude,
        code:         l.code,
        postal_code:  l.postal_code
      }
    end
    render text: location.to_json and return
  end

  def tag
  end

end
