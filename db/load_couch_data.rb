
birth_registration_types = BirthRegistrationType.all
birth_registration_types.each do |birth_registration_type|
    birth_registration_type_couchdb = BirthRegistrationTypeCouchdb.new
    birth_registration_type_couchdb.birth_registration_type_id = birth_registration_type.birth_registration_type_id
    birth_registration_type_couchdb.name = birth_registration_type.name
    birth_registration_type_couchdb.save
    puts "Loading birth_registration_type: #{birth_registration_type.name}"
end

education_levels = LevelOfEducation.all
education_levels.each do |education_level|
  level_of_education_couchdb = LevelOfEducationCouchdb.new
  level_of_education_couchdb.level_of_education_id = education_level.level_of_education_id
  level_of_education_couchdb.name = education_level.name
  level_of_education_couchdb.save
  puts "Loading LevelOfEducation: #{education_level.name}"
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
  location_couchdb.changed_by = location.changed_by
  location_couchdb.changed_at = location.changed_at
  location_couchdb.parent_location = location.parent_location
  location_couchdb.voided = location.voided
  location_couchdb.date_voided = location.date_voided
  location_couchdb.save
  puts "Loading Location: #{location.name}"
end

location_tags = LocationTag.all
location_tags.each do |location_tag|
  location_tag_couch_db = LocationTagCouchdb.new
  location_tag_couch_db.location_tag_id = location_tag.location_tag_id
  location_tag_couch_db.name = location_tag.name
  location_tag_couch_db.description = location_tag.description
  location_tag_couch_db.save
  puts "Loading LocationTag: #{location_tag.name}"
end

location_tag_maps = LocationTagMap.all
location_tag_maps.each do |location_tag_map|
  location_tag_map_couch_db = LocationTagMapCouchdb.new
  location_tag_map_couch_db.location_id = location_tag_map.location_id
  location_tag_map_couch_db.location_tag_id = location_tag_map.location_tag_id
  location_tag_map_couch_db.save
  puts "Loading LocationTag: #{location_tag_map.location_tag_id}"
end

mode_of_deliveries = ModeOfDelivery.all
mode_of_deliveries.each do |delivery_mode|
  mode_of_delivery_couch_db = ModeOfDeliveryCouchdb.new
  mode_of_delivery_couch_db.mode_of_delivery_id = delivery_mode.mode_of_delivery_id
  mode_of_delivery_couch_db.name = delivery_mode.name
  mode_of_delivery_couch_db.description = delivery_mode.description
  mode_of_delivery_couch_db.save
  puts "Loading ModeOfDelivery: #{delivery_mode.name}"
end

person_attribute_types = PersonAttributeType.all
person_attribute_types.each do |person_attribute_type|
  person_attribute_type_couch_db = PersonAttributeTypesCouchdb.new
  person_attribute_type_couch_db.person_attribute_type_id = person_attribute_type.person_attribute_type
  person_attribute_type_couch_db.name = person_attribute_type.name
  person_attribute_type_couch_db.description = person_attribute_type.description
  person_attribute_type_couch_db.save
  puts "Loading PersonAttributeType: #{person_attribute_type.name}"
end

person_relationship_types = PersonRelationType.all
person_relationship_types.each do |person_relationship_type|
  person_relationship_type_couch_db = PersonRelationshipTypesCouchdb.new
  person_relationship_type_couch_db.person_relationship_type_id = person_relationship_type.person_relationship_type_id
  person_relationship_type_couch_db.name = person_relationship_type.name
  person_relationship_type_couch_db.description = person_relationship_type.description
  person_relationship_type_couch_db.description = person_relationship_type.description
  person_relationship_type_couch_db.save
  puts "Loading PersonRelationType: #{person_relationship_type.name}"
end

person_type_of_births = PersonTypeOfBirth.all
person_type_of_births.each do |person_type_of_birth|
  person_type_of_births_couch_db = PersonTypeOfBirthsCouchdb.new
  person_type_of_births_couch_db.person_type_of_birth_id = person_type_of_birth.person_type_of_birth_id
  person_type_of_births_couch_db.name = person_type_of_birth.name
  person_type_of_births_couch_db.description = person_type_of_birth.description
  person_type_of_births_couch_db.save
  puts "Loading PersonTypeOfBirth: #{person_type_of_birth.name}"
end

person_types = PersonType.all
person_types.each do |t|
  person_type = PersonTypeCouchdb.create(
    person_type_id: t.id,
    name:           t.name,
    description:    t.description
  )
  puts "Loading PersonType: #{t.name}"
end

roles = Role.all
roles.each do |r|
  role = RoleCouchdb.create(
    role_id:  r.id,
    role:     r.role,
    level:    r.level
  )
  puts "Loading Role: #{r.role}"
end

statuses = Status.all
statuses.each do |status|
  status_couch_db = StatusCouchdb.new
  status_couch_db.status_id = status.status_id
  status_couch_db.name = status.name
  status_couch_db.description = status.description
  status_couch_db.save
  puts "Loading Status: #{status.name}"
end

puts "Init Couchdb (indexing) ...."
PersonTypeOfBirthsCouchdb.count
StatusCouchdb.count
PersonRelationshipTypesCouchdb.count
PersonAttributeTypesCouchdb.count
ModeOfDeliveryCouchdb.count
LocationTagMapCouchdb.count
LocationCouchdb.count
LocationTagCouchdb.count
LevelOfEducationCouchdb.count
BirthRegistrationTypeCouchdb.count
PersonTypeCouchdb.count
RoleCouchdb.count
puts "Init Couchdb (indexing) done ...."
