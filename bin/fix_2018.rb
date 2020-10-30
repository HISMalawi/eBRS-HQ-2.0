require 'csv'

CSV.foreach('/var/www/csv/2018.csv', headers: true) do |pid|
        person_id = pid['person_id']

        hq_printed = PersonRecordStatus.where(person_id: person_id, status_id: 39).first
        dc_printed = PersonRecordStatus.where(person_id: person_id, status_id: 62).first

        hq = hq_printed.status_id rescue nil
        dc = dc_printed.status_id rescue nil

#        next if hq.blank?
#        next if dc.blank?

        if hq.present?
        	prs = PersonRecordStatus.where(person_id: person_id, voided: 0).last
        	prs.status_id = 39
                prs.comments = "Corrected to HQ PRINTED"
        	prs.save
        	puts "Corrected to #{person_id} HQ PRINTED"
        elsif dc.present?
        	prs = PersonRecordStatus.where(person_id: person_id, voided: 0).last
        	prs.status_id = 62
                prs.comments = "Corrected to DC PRINTED"
        	prs.save
        	puts "Corrected to #{person_id} DC PRINTED"
        end
end
