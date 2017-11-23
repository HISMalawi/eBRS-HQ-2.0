require "rails"
district_code = ["BLK", "BT", "BTC", "CK", "CP", "CZ", "DA", "DZ", "KA", "KK", "KU", "LA", "LL", "LLC", "MC", "MH", "MHG", "MJ", "MN", "MZ", "MZC", "NB", "NE", "NN", "NS", "NU", "PE", "RU", "SA", "TO", "ZA", "ZAC"]
source  = YAML.load_file(Rails.root.join('config', 'sync_settings.yml'))[:source]
target  = YAML.load_file(Rails.root.join('config', 'sync_settings.yml'))[:target]

district_code.each do |code|
	   next if ["BTC","LLC","MZC","ZAC"].include?(code)
	   target_db = "#{target[:audit]}_#{code.downcase}"
	   create_db = "curl -X PUT #{target[:protocol]}://#{target[:username]}:#{target[:password]}@#{target[:host]}:#{target[:port]}/#{target_db}"
	   puts `#{create_db}`
	   sleep 3
	  
		begin
			target_to_source = %x[curl -k -H 'Content-Type: application/json' -S -X POST -d '#{{
		              	  source: "#{source[:protocol]}://#{source[:host]}:#{source[:port]}/#{source[:audit]}",
		                  target: "#{target[:protocol]}://#{target[:host]}:#{target[:port]}/#{target_db}",
		                  connection_timeout: 60000,
		                  filter: 'Audit/facility_sync',
		              		query_params: {
		        		     			district_code: "#{code}"
		                            }
		               		 }.to_json}' "#{target[:protocol]}://#{target[:username]}:#{target[:password]}@#{target[:host]}:#{target[:port]}/_replicate"]
		   
			    JSON.parse(target_to_source).each do |key, value|
			      puts "#{key.to_s.capitalize} : #{value.to_s.capitalize}"
			    end
			
		rescue Exception => e
			puts "#{code} clashed"
		end

	   
	puts "#{code} Audit sync started" 
end
district_code.each do |code|
	   next if ["BTC","LLC","MZC","ZAC"].include?(code)
	   target_db = "#{target[:primary]}_#{code.downcase}"
	   create_db = "curl -X PUT #{target[:protocol]}://#{target[:username]}:#{target[:password]}@#{target[:host]}:#{target[:port]}/#{target_db}"
	   puts `#{create_db}`
	   sleep 3
		begin
			target_to_source = %x[curl -k -H 'Content-Type: application/json' -S -X POST -d '#{{
		              	  source: "#{source[:protocol]}://#{source[:host]}:#{source[:port]}/#{source[:primary]}",
		                  target: "#{target[:protocol]}://#{target[:host]}:#{target[:port]}/#{target_db}",
		                  connection_timeout: 60000,
		                  filter: 'Child/district_sync',
		              		query_params: {
		        		     			district_code: "#{code}"
		                            }
		               		 }.to_json}' "#{target[:protocol]}://#{target[:username]}:#{target[:password]}@#{target[:host]}:#{target[:port]}/_replicate"]
		   
			    JSON.parse(target_to_source).each do |key, value|
			      puts "#{key.to_s.capitalize} : #{value.to_s.capitalize}"
			    end
			
		rescue Exception => e
			puts "#{code} clashed"
		end

	   
	puts "#{code} sync started" 
end