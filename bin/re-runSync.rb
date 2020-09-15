#person_ids = PersonBirthDetail.where(" date_registered > '2020-02-28' ").map(&:person_id)

status_id = Status.where(name: "HQ-CAN-PRINT").first.id

person_ids = PersonRecordStatus.find_by_sql("
         SELECT d.person_id FROM person_birth_details d
        INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
        WHERE d.person_id LIKE '100250%' AND d.national_serial_number IS NULL
         AND d.source_id LIKE '-%#%' AND d.created_at > '2020-01-01'  AND prs.status_id = #{status_id} AND prs.voided = 0
         ").map(&:person_id).uniq


person_ids.each_with_index do |pid, i|

#person_id = pid['person_id']
doc = Pusher.database.get(pid.to_s)
    fixed = false

    $models = {}
    Rails.application.eager_load!
    ActiveRecord::Base.send(:subclasses).map(&:name).each do |n|
      $models[eval(n).table_name] = n
    end

    if !doc.blank?
      doc = doc.as_json
      ordered_keys = (['core_person', 'person', 'users', 'user_role'] +
          doc.keys.reject{|k| ['_id', 'change_agent', '_rev', 'change_location_id',
                               'ip_addresses', 'location_id', 'type', 'district_id'].include?(k)}).uniq

      begin
        (ordered_keys || []).each do |table|
          next if doc[table].blank?

          doc[table].each do |p_value, data|
            record = eval($models[table]).find(p_value) rescue nil
            if !record.blank?
              record.update_columns(data)
            else
              record =  eval($models[table]).create(data)
            end

          end
        end

        fixed = true
        ErrorRecords.where(person_id: pid).each do |r|
          r.passed = 1
          r.save
        end

      rescue => e
        fixed = false
      end
	puts "#{pid}: #{fixed}"
    end
end
