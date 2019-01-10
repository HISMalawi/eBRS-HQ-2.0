action = ARGV[0]

raise "Missing action" if action.blank?

if action == "new_ids"

  raise "Missing json file for barcode numbers".to_s if (ARGV[1].blank? || !File.exist?(ARGV[1]))

  data = JSON.parse(File.read(ARGV[1]))

  data.first.last.each_with_index do |d, i|
    barcode = d['national_id']
    next if !BarcodeIdentifier.where(value: barcode).first.blank?

    puts "#{(i + 1)} # #{barcode}"
    BarcodeIdentifier.create(
        value: barcode,
        assigned: 0
    )
  end
elsif action == "assign_missing"

  bcd_type_id = PersonIdentifierType.where(name: "Barcode Number").last.id
  statuses    = Status.where(" name IN ('HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT', 'HQ-PRINTED') ").map(&:status_id)

  records =  PersonBirthDetail.find_by_sql("
    SELECT * FROM person_birth_details pbd
      LEFT JOIN person_identifiers pid ON pbd.person_id = pid.person_id AND pid.person_identifier_type_id = #{bcd_type_id}
      INNER JOIN person_record_statuses prs ON prs.person_id = pbd.person_id AND prs.voided = 0
      WHERE prs.status_id IN (#{statuses.join(', ')})
        AND (pbd.source_id IS NULL OR LENGTH(pbd.source_id) > 20)
        AND pid.person_identifier_id IS NULL
  ").map(&:person_id)

  records.each_with_index do |person_id, i|
    puts (i + 1)
    bcd = BarcodeIdentifier.where(assigned: 0).first
    raise "No Barcodes Left".to_s if bcd.blank?

    PersonIdentifier.create(
        person_id: person_id,
        person_identifier_type_id: bcd_type_id,
        value: bcd.value,
        voided: 0
    )

    bcd.person_id = person_id
    bcd.assigned  = 1
    bcd.save
  end
else
  raise "Unknown action: #{action}, AVAILABLE OPTIONS: new_ids, assign_missing"
end
