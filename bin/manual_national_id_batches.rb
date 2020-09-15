 mother_rel_ids = PersonRelationType.where(" name IN ('MOTHER', 'ADOPTIVE-MOTHER') ").collect{|r| r.id}
father_rel_ids = PersonRelationType.where(" name IN ('FATHER', 'ADOPTIVE-FATHER') ").collect{|r| r.id}
malawi_id      = Location.where(name: "Malawi").first.id

nid_type_id = PersonIdentifierType.where(:name => "National ID Number").last.person_identifier_type_id
status_ids = Status.where("name IN ('HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT') ").pluck :status_id

puts "Querying records with missing National IDs"
@person_ids = Person.find_by_sql(" SELECT person.person_id FROM person
        INNER JOIN person_birth_details pbd ON pbd.person_id = person.person_id AND (pbd.source_id IS NULL OR LENGTH(pbd.source_id) > 19)
        INNER JOIN person_record_statuses prs ON prs.person_id = person.person_id AND prs.voided = 0 AND prs.status_id IN (#{status_ids.join(', ')})
        LEFT JOIN person_relationship m_rel ON m_rel.person_a = person.person_id AND m_rel.person_relationship_type_id IN (#{mother_rel_ids.join(',')})
        LEFT JOIN person_relationship f_rel ON f_rel.person_a = person.person_id AND f_rel.person_relationship_type_id IN (#{father_rel_ids.join(',')})
        LEFT JOIN person_addresses m_adr ON m_adr.person_id = m_rel.person_b
        LEFT JOIN person_addresses f_adr ON f_adr.person_id = f_rel.person_b
        LEFT JOIN identifier_allocation_queue q ON q.person_id = person.person_id
          AND assigned = 0 AND person_identifier_type_id = #{nid_type_id}
        WHERE q.person_id IS NULL AND TIMESTAMPDIFF(YEAR, NOW(), person.birthdate) < 16
          AND (COALESCE(m_adr.citizenship, #{malawi_id}) = #{malawi_id} AND COALESCE(f_adr.citizenship, #{malawi_id}) = #{malawi_id})
      ").map(&:person_id).uniq


user = User.where(username: 'admin279').first
@person_ids.each_slice(1000).each do |chunk|
    puts @person_ids.length
   PersonService.request_nris_ids_by_batch(chunk, "N/A", user)
end 
