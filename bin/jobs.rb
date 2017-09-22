#This file is used to sync data birectional from and to all enabled sites
#Kenneth Kapundi@21/Sept/2017

require 'open3'
def is_up?(host)
  host, port = host.split(':')
  a, b, c = Open3.capture3("nc -vw 5 #{host} #{port}")
  b.scan(/succeeded/).length > 0
end

data = YAML.load_file("#{Rails.root}/public/sites.yml") rescue {}
data.each do |site_id, d|
  next if d.blank?
  (d['ip_addresses'] || []).each do |adr|
    if is_up?(adr)
      data[site_id]['online'] = true
      data[site_id]['last_seen'] = "#{Time.now}"
      next
    else
      data[site_id]['online'] = false
    end
  end
end

data['last_run'] = "#{Time.now}"

File.open("#{Rails.root}/public/sites.yml","w") do |file|
  file.write data.to_yaml
end


