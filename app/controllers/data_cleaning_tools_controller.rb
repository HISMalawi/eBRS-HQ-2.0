class DataCleaningToolsController < ApplicationController

  def missing_national_ids
    #Query All Less Than 16 in Print Queue
    mother_rel_ids = PersonRelationType.where(" name IN ('MOTHER', 'ADOPTIVE-MOTHER') ").collect{|r| r.id}
    father_rel_ids = PersonRelationType.where(" name IN ('FATHER', 'ADOPTIVE-FATHER') ").collect{|r| r.id}
    malawi_id      = Location.where(name: "Malawi").first.id

    nid_type_id = PersonIdentifierType.where(:name => "National ID Number").last.person_identifier_type_id
    status_ids = Status.where("name IN ('HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT') ").pluck :status_id
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

    File.open("missing_national_ids.json", "w"){|f| f.write(@person_ids.to_json)}

  end


  def missing_barcode_numbers
    status_ids = Status.where("name IN ('HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT') ").pluck :status_id

    barcode_number_id = PersonIdentifierType.where(name: "Barcode Number").first.id
    @person_ids = PersonBirthDetail.find_by_sql(
      "SELECT pbd.person_id FROM person_birth_details pbd
        INNER JOIN person_record_statuses prs ON prs.person_id = pbd.person_id AND prs.voided = 0 AND prs.status_id IN (#{status_ids.join(',')})
        LEFT JOIN person_identifiers pid ON pid.person_id = pbd.person_id AND pid.person_identifier_type_id = #{barcode_number_id}
        WHERE pid.person_id IS NULL AND (pbd.source_id IS NULL OR LENGTH(pbd.source_id) > 19)
      ").map(&:person_id).uniq

    File.open("missing_barcode_numbers.json", "w"){|f| f.write(@person_ids.to_json)}

    @free = BarcodeIdentifier.where(assigned: 0).count
  end

  def queue_for_nid_assignment
    person_ids = JSON.parse(File.read("missing_national_ids.json"))

    if person_ids.length > 0
      nid_type_id = PersonIdentifierType.where(:name => "National ID Number").last.person_identifier_type_id
      person_ids.each do |person_id|
        allocation = IdentifierAllocationQueue.new
        allocation.person_id = person_id
        allocation.assigned = 0
        allocation.creator = User.current.id
        allocation.person_identifier_type_id = nid_type_id
        allocation.created_at = Time.now
        allocation.save
      end
    end

    redirect_to "/data_cleaning_tools/missing_national_ids"
  end

  def assign_missing_barcode_numbers

    person_ids = JSON.parse(File.read("missing_barcode_numbers.json"))
    if person_ids.length > 0

      person_ids.each do |person_id|
        puts person_id
        barcode = BarcodeIdentifier.where(assigned: 0).first
        PersonIdentifier.new_identifier(person_id, "Barcode Number", barcode.value)
        barcode.assigned = 1
        barcode.save
      end
    end

    redirect_to "/data_cleaning_tools/missing_barcode_numbers"
  end
end
