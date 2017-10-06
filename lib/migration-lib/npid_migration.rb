$configs = YAML.load_file("#{Rails.root}/config/couchdb.yml")['npid_migration']
$database = "#{$configs['prefix']}_npid_#{$configs['suffix']}".gsub(/^\_|\_$/, '')
$couch_link = "#{$configs['protocol']}://#{$configs['username']}:#{$configs['password']}@#{$configs['host']}:#{$configs['port']}/#{$database}/"
$couch_link += "_design/User/_view/all?include_docs=true"

users = JSON.parse(`curl -X GET #{$couch_link}`)

