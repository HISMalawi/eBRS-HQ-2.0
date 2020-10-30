require 'csv'

CSV.foreach('/var/www/csv/za_nid.csv', headers: true) do |pid|
        person_id = pid['person_id']
        a = PersonService.request_nris_id(person_id, "N/A", 1002792)
        #a = PersonService.force_sync(person_id)
        puts "#{person_id}: #{a}"
end


