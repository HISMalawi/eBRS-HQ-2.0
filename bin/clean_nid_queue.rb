
raw_queue = IdentifierAllocationQueue.where(assigned: 0, person_identifier_type_id: 4)

puts "Total In Queue: #{raw_queue.count}"

raw_person_ids = raw_queue.map(&:person_id)

with_nids = PersonIdentifier.where(" value IS NOT NULL AND  person_identifier_type_id = 4 AND person_id IN (#{raw_person_ids.join(',')}) ")

#without_nids = raw_person_ids - with_nids.map(&:person_id)

with_nids = with_nids.map(&:person_id)

IdentifierAllocationQueue.connection.update(" UPDATE identifier_allocation_queue SET assigned = 1 WHERE  person_id IN (#{with_nids.join(',')}) ")

puts with_nids.count
