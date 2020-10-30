raw_queue = IdentifierAllocationQueue.where(assigned: 0, person_identifier_type_id: 4)

puts "Total In Queue: #{raw_queue.count}"

raw_person_ids = raw_queue.map(&:person_id)

with_nids = PersonIdentifier.where(" value IS NOT NULL AND  person_identifier_type_id = 4 AND person_id IN (#{raw_person_ids.join(',')}) ")

without_nids = raw_person_ids - with_nids.map(&:person_id)

puts "Without National IDs: #{without_nids.count}"

without_nids.each_with_index do |person_id, i|
 
  a = PersonService.request_nris_id(person_id, "N/A", 1002792) rescue nil

  new_nid = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: 4).first
  new_id = new_nid.value rescue nil

  if new_id.blank?
     puts "#{i} ## #{person_id}## could not generate National ID"
  end

  next if new_id.blank?
  new_nid.save

  puts "#{i} ## #{person_id} ## #{new_id}"


end

