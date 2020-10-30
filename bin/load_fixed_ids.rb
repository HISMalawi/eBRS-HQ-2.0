person_ids = File.read(ARGV[0]).split("\n")

models = {}
Rails.application.eager_load!
ActiveRecord::Base.send(:subclasses).map(&:name).each do |n|
  models[eval(n).table_name] = n
end

person_ids.each do  |pid|
  
  next if pid.blank?
  puts "########{pid}##########"
 

  PersonService.force_sync(pid, models)
 
end
