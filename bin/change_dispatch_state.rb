Dir["#{Rails.root}/tmp/*"].each do |d|
    next unless d.include?("dispatch-")
    File.foreach(d) do |id|
        puts "Dispatch : #{id}"
        next if id.blank?
        status = PersonRecordStatus.where("person_id=#{id} AND voided=0 AND status_id IN (SELECT status_id FROM statuses WHERE name = 'HQ-DISPATCHED')")
        if status.blank?
            puts "Skip"
        else
            PersonRecordStatus.new_record_state(id, "HQ-DISPATCHED", "DC-DISPATCHED")
        end
    end
    `rm #{d}`
end