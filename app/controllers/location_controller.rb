class LocationController < ApplicationController
  def index
    allowed_tags = ["Country", "District", "Traditional Authority", "Village", "Health Facility"]
    allowed_tag_ids = allowed_tags.collect{|tag_name| LocationTag.where(name: tag_name).first.id}

  end

  def tags
    @location_tags = LocationTag.where(" voided = 0 ").order('name')
  end

  def new
    @location = Location.new
    #@tags = LocationTag.all.each_slice(4).to_a
    @parent_locations = []
    @tag_type_id = nil
    if params[:cat] && ['village', 'ta', 'facility'].include?(params[:cat])
      tag_type_id = LocationTag.where(name: "District").first.id
      @parent_locations = Location.find_by_sql("SELECT name, l.location_id FROM location l
                            INNER JOIN location_tag_map tm ON tm.location_id = l.location_id
                            WHERE tm.location_tag_id = #{tag_type_id} ").collect{|x| [x.location_id, x.name]}
    end

    case params[:cat]
      when 'village'
        @tag_type_id = LocationTag.where(name: "Village").first.id
      when 'ta'
        @tag_type_id = LocationTag.where(name: "Traditional Authority").first.id
      when 'district'
        @tag_type_id = LocationTag.where(name: "District").first.id
      when 'facility'
        @tag_type_id = LocationTag.where(name: "Health Facility").first.id
      when 'country'
        @tag_type_id = LocationTag.where(name: "Country").first.id
    end

    @action = "/location/new"
    if request.post?
      parent_location = params[:parent_location_ta]
      parent_location = params[:parent_location] if parent_location.blank?

      l = Location.create(
          name: params[:name],
          code: params[:code],
          parent_location: parent_location,
          description: params[:description]
      )

      (params[:tags] || []).each do |tag|
        LocationTagMap.create(location_id: l.id, location_tag_id: tag)
      end
      redirect_to "/location/index" and return
    end
  end

  def edit
    @action = "/location/edit"
    @location = Location.find(params[:location_id])
    #@tags = LocationTag.all.each_slice(4).to_a
    @tag = LocationTagMap.where(location_id: @location.id).last
    @parent_loc   = Location.where(location_id: @location.parent_location).first
    @parent_tag   = LocationTag.find(@tag.location_tag_id)

    @parent_district = nil
    @parent_locations = []
    @tag_type_id = @tag.location_tag_id

    if !@parent_tag.blank? && ['Village', 'Traditional Authority', 'Health Facility'].include?(@parent_tag.name)
      tag_type_id = LocationTag.where(name: "District").first.id
      @parent_locations = Location.find_by_sql("SELECT name, l.location_id FROM location l
                        INNER JOIN location_tag_map tm ON tm.location_id = l.location_id
                        WHERE tm.location_tag_id = #{tag_type_id} ").collect{|x| [x.location_id, x.name]}
    end

    if !@parent_tag.blank? && 'Village' == @parent_tag.name
      tag_type_id = LocationTag.where(name: "Traditional Authority").first.id
      @tas = Location.find_by_sql("SELECT name, l.location_id FROM location l
                        INNER JOIN location_tag_map tm ON tm.location_id = l.location_id
                        WHERE tm.location_tag_id = #{tag_type_id}
                          AND parent_location = #{@parent_loc.parent_location}").collect{|x| [x.location_id, x.name]}
      @parent_district    = Location.find(@parent_loc.parent_location)
    end

    if request.post?
      parent_location = params[:parent_location_ta]
      parent_location = params[:parent_location] if parent_location.blank?

      @location.name = params[:name]
      @location.code = params[:code]
      @location.description = params[:description]
      @location.parent_location = parent_location
      @location.save

      LocationTagMap.where(location_id: @location.id).delete_all
      (params[:tags] || []).each do |tag|
        LocationTagMap.create(location_id: @location.id, location_tag_id: tag)
      end
      redirect_to "/location/index" and return
    end
  end

  def view
    @location = Location.find(params[:location_id])
    @tags = LocationTagMap.where(location_id: @location.id).collect{|l| LocationTag.find(l.location_tag_id).name}
  end

  def ajax_locations

    search_val = params[:search][:value] rescue nil
    search_val = '_' if search_val.blank?
    tag_filter = ''

    if params[:tag_id].present?
      location_ids = LocationTagMap.find_by_sql(" SELECT m.location_id FROM location_tag_map m WHERE m.location_tag_id = #{params[:tag_id]}").map(&:location_id) + [-1]
      tag_filter = " AND location.location_id IN (#{location_ids.join(', ')}) "
    end

    data = Location.order(' location.name ')
    data = data.where(" ( location.name LIKE '%#{search_val}%' #{tag_filter} OR  location.code LIKE '%#{search_val}%' #{tag_filter} ) ")
    total = data.select(" count(*) c ")[0]['c'] rescue 0
    page = (params[:start].to_i / params[:length].to_i) + 1

    data = data.select(" location.* ")
    data = data.page(page).per_page(params[:length].to_i)

    @records = []
    data.each do |p|
      types = (LocationTag.find_by_sql("SELECT name FROM location_tag WHERE location_tag_id IN
                (SELECT location_tag_id FROM location_tag_map WHERE location_id = #{p.location_id})")).map(&:name)
      row = [p.name.force_encoding('utf-8').encode,
             p.code.to_s, types.join(', '),
             (Location.find(p.parent_location).name.force_encoding('utf-8').encode rescue nil),  p.location_id]
      @records << row
    end

    render :text => {
        "draw" => params[:draw].to_i,
        "recordsTotal" => total,
        "recordsFiltered" => total,
        "data" => @records}.to_json and return
  end

  def delete
    LocationTagMap.where(location_id: params[:location_id]).delete_all

    loc = Location.find(params[:location_id])
    if (loc.destroy rescue false)
      flash[:error] = "Successfully deleted location type"
    else
      flash[:error] = "Location already in use by some items"
    end

    redirect_to '/location/index'
  end

  def get_location
    location = []
    from  = params[:record_limit].to_i
    to    = 800

    location_tag = LocationTag.find(params[:location_tag_id])
    tag_name = location_tag.name

    locations = Location.group("location.location_id").where("t.location_tag_id = ?",
      location_tag.id).joins("INNER JOIN location_tag_map m 
      ON m.location_id = location.location_id
      INNER JOIN location_tag t 
      ON t.location_tag_id = m.location_tag_id").limit("#{from}, #{to}").order("location.location_id ASC")

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
        district = Location.find(l.parent_location).name
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

    render text: location.to_json
  end

  def tag
    if params[:location_tag] == 'vl'
      location_tag = LocationTag.where(name: 'District').first

      @districts = Location.group("location.location_id").where("t.location_tag_id = ?",
        location_tag.id).joins("INNER JOIN location_tag_map m 
        ON m.location_id = location.location_id
        INNER JOIN location_tag t 
        ON t.location_tag_id = m.location_tag_id").order("location.name ASC")
    end
  end

  def tas
    district = params[:parent]
    district_tag_id = LocationTag.where(name: "District").first.id
    tag_id = LocationTag.where(name: "Traditional Authority").first.id

    district_id = Location.find_by_sql(
        "SELECT l.location_id FROM location l
          INNER JOIN location_tag_map m ON l.location_id = m.location_id
          WHERE m.location_tag_id = #{district_tag_id} AND l.location_id = '#{district}' "
    ).last.location_id

    locations = Location.find_by_sql(
        "SELECT l.location_id, l.name FROM location l
          INNER JOIN location_tag_map m ON l.location_id = m.location_id
          WHERE m.location_tag_id = #{tag_id} AND l.parent_location = #{district_id}").collect{|s| [s.location_id, s.name.force_encoding('utf-8').encode]}

    render text: (locations).to_json
  end

  def get_traditional_authorities
    district = Location.find(params[:district_id])
    location_tag = LocationTag.where(name: 'Traditional Authority').first

    tas = Location.group("location.location_id").where("t.location_tag_id = ?
      AND parent_location = ?", location_tag.id, district.id).joins("INNER JOIN location_tag_map m 
        ON m.location_id = location.location_id
        INNER JOIN location_tag t 
        ON t.location_tag_id = m.location_tag_id").order("location.name ASC")

    traditional_authorities = []
    
    (tas || []).each do |l|
      traditional_authorities << {
        location_id:  l.id,
        name:         l.name,
        district:     district.name,
        location_id:  l.id
      } 
    end 

    render text: traditional_authorities.to_json
  end

  def get_villages
    ta = Location.find(params[:ta_id])
    district = Location.find(ta.parent_location).name
    location_tag = LocationTag.where(name: 'Village').first

    villages_fetched = Location.group("location.location_id").where("t.location_tag_id = ?
      AND parent_location = ?", location_tag.id, ta.id).joins("INNER JOIN location_tag_map m 
        ON m.location_id = location.location_id
        INNER JOIN location_tag t 
        ON t.location_tag_id = m.location_tag_id").order("location.name ASC")

    villages = []
    
    (villages_fetched || []).each do |l|
      villages << {
        location_id:  l.id,
        name:         l.name,
        ta:           ta.name,
        district:     district
      } 
    end 

    render text: villages.to_json
  end


end
