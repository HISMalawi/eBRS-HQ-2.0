
birth_registration_types = BirthRegistrationType.all
birth_registration_types.each do |birth_registration_type|
    birth_registration_type_couchdb = BirthRegistrationTypeCouchdb.new
    birth_registration_type_couchdb.birth_registration_type_id = birth_registration_type.birth_registration_type_id
    birth_registration_type_couchdb.name = birth_registration_type.name
    birth_registration_type_couchdb.save
end

education_levels = LevelOfEducation.all
education_levels.each do |education_level|
  level_of_education_couchdb = LevelOfEducationCouchdb.new
  level_of_education_couchdb.level_of_education_id = education_level.level_of_education_id
  level_of_education_couchdb.name = education_level.name
  level_of_education_couchdb.save
end

locations = Location.all
locations.each do |location|
  location_couchdb = LocationCouchdb.new
  location_couchdb.location_id = location.location_id
  location_couchdb.code = location.code
  location_couchdb.name = location.name
  location_couchdb.description = location.description
  location_couchdb.postal_code = location.postal_code
  location_couchdb.country = location.country
  location_couchdb.latitude = location.latitude
  location_couchdb.longitude = location.longitude
  location_couchdb.county_district = location.county_district
  location_couchdb.creator = location.creator
  location_couchdb.created_at = location.created_at
  location_couchdb.changed_by = location.changed_by
  location_couchdb.changed_at = location.changed_at
  location_couchdb.save
end

location_tags = LocationTag.all
location_tags.each do |location_tag|
  location_tag_couch_db = LocationTagCouchdb.new
  location_tag_couch_db.location_tag_id = location_tag.location_tag_id
  location_tag_couch_db.name = location_tag.name
  location_tag_couch_db.description = location_tag.description
  location_tag_couch_db.updated_at = location_tag.updated_at
  location_tag_couch_db.created_at = location_tag.created_at
  location_tag_couch_db.save
end

location_tag_maps = LocationTagMap.all
location_tag_maps.each do |location_tag_map|
  location_tag_map_couch_db = LocationTagMapCouchdb.new
  location_tag_map_couch_db.location_id = location_tag_map.location_id
  location_tag_map_couch_db.location_tag_id = location_tag_map.location_tag_id
  location_tag_map_couch_db.save
end

mode_of_deliveries = ModeOfDelivery.all
mode_of_deliveries.each do |delivery_mode|
  mode_of_delivery_couch_db = ModeOfDeliveryCouchdb.new
  mode_of_delivery_couch_db.mode_of_delivery_id = delivery_mode.mode_of_delivery_id
  mode_of_delivery_couch_db.name = delivery_mode.name
  mode_of_delivery_couch_db.description = delivery_mode.description
  mode_of_delivery_couch_db.created_at = delivery_mode.created_at
  mode_of_delivery_couch_db.updated_at = delivery_mode.updated_at
  mode_of_delivery_couch_db.save
end

person_attribute_types = PersonAttributeType.all
person_attribute_types.each do |person_attribute_type|
  person_attribute_type_couch_db = PersonAttributeTypesCouchdb.new
  person_attribute_type_couch_db.person_attribute_type_id = person_attribute_type.person_attribute_type
  person_attribute_type_couch_db.name = person_attribute_type.name
  person_attribute_type_couch_db.description = person_attribute_type.description
  person_attribute_type_couch_db.created_at = person_attribute_type.created_at
  person_attribute_type_couch_db.updated_at = person_attribute_type.updated_at
  person_attribute_type_couch_db.save
end

person_relationship_types = PersonRelationType.all
person_relationship_types.each do |person_relationship_type|
  person_relationship_type_couch_db = PersonRelationshipTypesCouchdb.new
  person_relationship_type_couch_db.person_relationship_type_id = person_relationship_type.person_relationship_type_id
  person_relationship_type_couch_db.name = person_relationship_type.name
  person_relationship_type_couch_db.description = person_relationship_type.description
  person_relationship_type_couch_db.description = person_relationship_type.description
  person_relationship_type_couch_db.save
end

person_type_of_births = PersonTypeOfBirth.all
person_type_of_births.each do |person_type_of_birth|
  person_type_of_births_couch_db = PersonTypeOfBirthsCouchdb.new
  person_type_of_births_couch_db.person_type_of_birth_id = person_type_of_birth.person_type_of_birth_id
  person_type_of_births_couch_db.name = person_type_of_birth.name
  person_type_of_births_couch_db.description = person_type_of_birth.description
  person_type_of_births_couch_db.created_at = person_type_of_birth.created_at
  person_type_of_births_couch_db.updated_at = person_type_of_birth.updated_at
  person_type_of_births_couch_db.save
end

statuses = Status.all
statuses.each do |status|
  status_couch_db = StatusCouchdb.new
  status_couch_db.status_id = status.status_id
  status_couch_db.name = status.name
  status_couch_db.description = status.description
  status_couch_db.created_at = status.created_at
  status_couch_db.updated_at = status.updated_at
  status_couch_db.save
end