time = Time.now
errors         = []
failed_batches = []

status_ids = Status.where('
  name IN ("HQ-PRINTED", "HQ-DISPATCHED", "HQ-AMEND", "DC-AMEND",
  "DC-AMEND-REJECTED", "HQ-AMEND", "HQ-AMEND-GRANTED", "HQ-AMEND-REJECTED",
  "HQ-AMEND-REJECTED-TBA", "HQ-CAN-REPRINT-AMEND") ').map(&:status_id)

records = PersonRecordStatus.where("status_id IN (#{status_ids.join(', ')}) AND voided = 0").select("person_id").map(&:person_id)
File.open("#{Rails.root}/all_records", "w"){|f| f.write(records)}
total = records.count
puts "Total Records Found: #{total}"

chunks  = records.each_slice(1000).to_a
chunks.each_with_index do |chunk, i|

  success, er = PersonService.request_nris_ids_by_batch(chunk, "eBRS-Server", User.where(username: "admin279").first)
  puts "Batch: #{(i + 1)}000 / #{total} :: #{success.to_s.upcase}"


  if !er.blank?
    errors << er.values
    errors = errors.flatten
  end

  if success == false
    failed_batches << chunk
  end
end

time2 = Time.now

File.open("#{Rails.root}/errors", "w"){|f| f.write(errors)}
File.open("#{Rails.root}/failed_batches", "w"){|f| f.write(failed_batches)}


