require 'csv'

CSV.foreach('/var/www/zomba_fixed_ids.csv', headers: true) do |pid|
        person_id = pid['person_id']
        a = PersonService.force_sync(person_id) rescue nil
        puts "#{person_id}: #{a}"
end

