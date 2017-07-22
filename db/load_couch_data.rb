SERVER = CouchRest.new
configs = YAML.load_file("#{Rails.root}/config/couchdb.yml")[Rails.env]
DB = SERVER.database!("#{configs['prefix']}_#{configs['suffix']}")

class Pusher < CouchRest::Document
  use_database(DB)
end

def send_data(hash)
  hash = Pusher.new(hash)
  hash.save
  hash['document_id'] = hash.id
  hash.save

  hash.id
end

puts "Loading Data to Couch ...."

(   BirthRegistrationType.all +
    LevelOfEducation.all +
    Location.all +
    LocationTag.all +
    LocationTagMap.all +
    ModeOfDelivery.all +
    PersonAttributeType.all +
    PersonRelationType.all +
    PersonTypeOfBirth.all +
    PersonType.all +
    Role.all +
    Status.all
).each do |data|

    transformed_data = data.as_json
    transformed_data.delete("#{eval(data.class.name).primary_key}")
    transformed_data['type'] = eval(data.class.name).table_name
    doc_id = send_data(transformed_data)
    data.update_attributes(:document_id => doc_id)
end

puts "Done Loading Data to Couch!!"

