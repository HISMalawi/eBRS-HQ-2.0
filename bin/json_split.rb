require 'json'
records = Oj.load File.read("#{Rails.root}/data.json")
records['rows'] = records['rows'].sort_by { |r|  r[:district_id_number].split(/\//)[1].to_i rescue nil}
start =  Time.now
puts "Chuncking files"
file_number = 0

if Dir.exists?(File.expand_path("~/")+"/ebrs_chuncks")

else
	Dir.mkdir(File.expand_path("~/")+"/ebrs_chuncks")
	records['rows'].each_slice(1000).to_a.each_with_index do |block|

	 	file_path = "#{File.expand_path("~/")}/ebrs_chuncks/#{file_number}.json"
	 	if !File.exists?(file_path)
	           file = File.new(file_path, 'w')
	           File.open(file_path, 'w') do |f|
		          f.puts "#{block.to_json}"

		      end
	    else

	       File.open(file_path, 'w') do |f|
	          f.puts "#{block.to_json}"

	      end
	    end
	    file_number = file_number + 1
	 	puts Time.now
	end
end


puts "\"Time taken\" : #{(Time.now - start)/60} , \"count\" : #{records["rows"].count}"