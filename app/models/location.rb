class Location < ActiveRecord::Base
  include EbrsMetadata

  self.table_name = :location
  self.primary_key = :location_id
  has_many  :users
  has_one   :location_tag_map, class_name: 'LocationTagMap', foreign_key: 'location_id'


  cattr_accessor :current_district
  cattr_accessor :current_health_facility
  cattr_accessor :current
    
  def facility_district
    if self.parent_location.blank?
      return self 
    else
      if self.location_tag_map.location_tag.name.match(/Health facility/i)
        return Location.find(self.parent_location)
      else
        return nil
      end
    end

  end

  def district(raw=false)
    ta = self.ta(true)
    if !ta.blank?
      tag = LocationTag.where(name: 'District').last.id
      tag_map = LocationTagMap.where(location_tag_id: tag, location_id: ta.parent_location)

      if tag_map.present?
        if raw
          return Location.find(ta.parent_location)
        else
          return Location.find(ta.parent_location).name
        end
      end
    end

    tag = LocationTag.where(name: 'District').last.id
    tag_map = LocationTagMap.where(location_tag_id: tag, location_id: self.id)

    if tag_map.present?
      if raw
        return self
      else
        return self.name
      end
    end
  end

  def ta(raw=false)
    tag = LocationTag.where(name: 'Village').last.id
    tag_map = LocationTagMap.where(location_tag_id: tag, location_id: self.id)

    if tag_map.present?
      tag = LocationTag.where(name: 'Traditional Authority').last.id
      tag_map = LocationTagMap.where(location_tag_id: tag, location_id: self.parent_location)
      if tag_map.present?
        if raw
          return Location.find(self.parent_location)
        else
          return Location.find(self.parent_location).name
        end
      end
    else
      tag = LocationTag.where(name: 'Traditional Authority').last.id
      tag_map = LocationTagMap.where(location_tag_id: tag, location_id: self.id)

      if tag_map.present?
        if raw
          return self
        else
          return self.name
        end
      end
    end

    return nil
  end

  def village(raw=false)
    tag = LocationTag.where(name: 'Village').last.id
    tag_map = LocationTagMap.where(location_tag_id: tag, location_id: self.id)
    if tag_map.present?
      if raw
        return self
      else
        return self.name
      end
    else
      return nil
    end
  end

  def self.locate_id(name, tag, parent_id)
    tag_id = LocationTag.where(name: tag).last.id rescue nil
    if tag.upcase == "TRADITIONAL AUTHORITY"
      name = [name, ("SC " + name), ("S/C " + name), ("TA " + name), ("STA " + name)]
    else
      name = [name]
    end

    LocationTagMap.find_by_sql(["SELECT * FROM location_tag_map m INNER JOIN location l ON l.location_id = m.location_id
      WHERE m.location_tag_id = #{tag_id} AND l.parent_location = #{parent_id} AND l.name IN (?)", name]).last.location_id  rescue nil
  end

  def self.hospitals_in(parent_id)
    tag_id = LocationTag.where(name: "Health Facility").last.id rescue nil
    LocationTagMap.find_by_sql("SELECT * FROM location_tag_map m INNER JOIN location l ON l.location_id = m.location_id
      WHERE m.location_tag_id = #{tag_id} AND l.parent_location = #{parent_id} " ).collect{|l| l.location_id} rescue nil
  end

  def self.locate_id_by_tag(name, tag)
    if tag.upcase == "TRADITIONAL AUTHORITY"
      name = [name, ("SC " + name), ("S/C " + name), ("TA " + name), ("STA " + name)]
    else
      name = [name]
    end

    tag_id = LocationTag.where(name: tag).last.id rescue nil
    LocationTagMap.find_by_sql(["SELECT * FROM location_tag_map m INNER JOIN location l ON l.location_id = m.location_id
      WHERE m.location_tag_id = #{tag_id} AND l.name IN (?) ", name]).last.location_id  rescue nil
  end

  def children
    return ActiveRecord::Base.connection.select_all("SELECT location_id from location WHERE parent_location = #{self.id}").collect{|s| s["location_id"]}
  end

  def self.find_or_create_ta(name, district_id)
    l = Location.where(:name => name, :parent_location => district_id).last
    return l.id if !l.blank?

    ta = Location.create(
        :name => name,
        :parent_location => district_id,
        :description => "nid_ta"
    )

    tag_id = LocationTag.where(name: "Traditional Authority").last.id
    LocationTagMap.create(
        :location_id => ta.id,
        :location_tag_id => tag_id
    )

    ta.id
  end

  def self.find_or_create_village(name, ta_id)
    l = Location.where(:name => name, :parent_location => ta_id).last
    return l.id if !l.blank?

    vg = Location.create(
        :name => name,
        :parent_location => ta_id,
        :description => "nid_village"
    )

    tag_id = LocationTag.where(name: "Village").last.id
    LocationTagMap.create(
        :location_id => vg.id,
        :location_tag_id => tag_id
    )

    vg.id
  end

  def self.find_or_create_facility(name, district_id)
    l = Location.where(:name => name, :parent_location => district_id).last
    return l.id if !l.blank?

    fa = Location.create(
        :name => name,
        :parent_location => district_id,
        :description => "nid_facility"
    )

    tag_id = LocationTag.where(name: "Health Facility").id
    LocationTagMap.create(
        :location_id => fa.id,
        :location_tag_id => tag_id
    )

    fa.id
  end

  def self.child_locations_for(loc_id, depth=1)
    results = []
    parent_locs = Location.where(parent_location: loc_id).pluck :location_id
    results     = parent_locs

    if depth == 2
      parent_locs.each do |l_id|
        results += Location.where(parent_location: l_id).pluck :location_id
      end
    end

    results
  end
end
