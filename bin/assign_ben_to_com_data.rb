require 'csv'

CSV.foreach('/var/www/bens1.csv', headers: true) do |pid|
        person_id = pid['person_id']

        b = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: 2).first
        ben = b.value

        pbd = PersonBirthDetail.where(person_id: person_id).first
        pbd.district_id_number = ben
        pbd.save
     
        puts "#{person_id}: #{ben}"
end
