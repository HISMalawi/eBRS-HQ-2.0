$configs = YAML.load_file("#{Rails.root}/config/couchdb.yml")['npid_migration']
$database = "#{$configs['prefix']}_npid_#{$configs['suffix']}".gsub(/^\_|\_$/, '')
$couch_link = "#{$configs['protocol']}://#{$configs['username']}:#{$configs['password']}@#{$configs['host']}:#{$configs['port']}/#{$database}/"
$couch_link += "_design/Npid/_view/all?include_docs=true&limit=10"
$npid_type = PersonIdentifierType.where(name: "Barcode Number").last.id
=begin
{"id"=>"99999",
"key"=>"99999",
"value"=>nil,
"doc"=>{"_id"=>"99999",
    "_rev"=>"1-a4b1896b1d14169c58034076765b2ce2",
    "national_id"=>"0003K654",
    "type"=>"Npid",
    "created_at"=>"2016-06-13 11:11:30 +0200",
    "assigned"=>false
  }
}
 
#<BarcodeIdentifier
  barcode_identifier_id: nil,
  value: nil,
  assigned: 0,
  person_id: nil,
  update_at: nil,
  created_at: nil
>
=end
puts $couch_link
npids = JSON.parse(`curl -s -X GET #{$couch_link}`) rescue {}
npids['rows'] = [] if npids['rows'].blank?
total = npids['rows'].count
puts "#{total}".to_s
npids['rows'].each_with_index do |pid, i|
  pid = pid['doc']

  bcd = BarcodeIdentifier.where(:value => pid['national_id'].strip)
  next if !bcd.blank?
  next if pid['assigned'] == true

  if ((i + 1) % 1000 == 0)
    puts "Position #: #{(i + 1)}"
  end 
  ActiveRecord::Base.connection.execute <<EOF
        INSERT INTO barcode_identifiers(value, assigned) VALUES ('#{pid["national_id"].strip}', 0)
EOF
end

