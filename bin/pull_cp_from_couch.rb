require 'csv'

CSV.foreach('/var/www/csv/data4.csv', headers: true) do |pid|
        person_id = pid['person_id']
        a = PersonService.force_sync(person_id)
        puts "#{person_id}: #{a}"
end


