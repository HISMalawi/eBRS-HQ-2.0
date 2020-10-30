# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
require "bantu_soundex"
require "csv"
require "simple_elastic_search"
require "nid_validator"

module PrettyDate
  def to_pretty
    a = (Time.now-self).to_i

    case a
      when 0 then 'just now'
      when 1 then 'a second ago'
      when 2..59 then a.to_s+' seconds ago'
      when 60..119 then 'a minute ago' #120 = 2 minutes
      when 120..3540 then (a/60).to_i.to_s+' minutes ago'
      when 3541..7100 then 'an hour ago' # 3600 = 1 hour
      when 7101..82800 then ((a+99)/3600).to_i.to_s+' hours ago'
      when 82801..172000 then 'a day ago' # 86400 = 1 day
      when 172001..518400 then ((a+800)/(60*60*24)).to_i.to_s+' days ago'
      when 518400..1036800 then 'a week ago'
      else ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
    end
  end
end

Time.send :include, PrettyDate

class Pusher <  CouchRest::Model::Base
  configs = YAML.load_file("#{Rails.root}/config/couchdb.yml")[Rails.env]
  connection.update({
                        :protocol => "#{configs['protocol']}",
                        :host     => "#{configs['host']}",
                        :port     => "#{configs['port']}",
                        :prefix   => "#{configs['prefix']}",
                        :suffix   => "#{configs['suffix']}",
                        :join     => '_',
                        :username => "#{configs['username']}",
                        :password => "#{configs['password']}"
                    })
end


