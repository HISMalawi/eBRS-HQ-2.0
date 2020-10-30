#This script builds the certificate table
#by combining data from eBRS V1 and V2
#Written by: Kenneth Kapundi
#Date: 05 February, 2019

print_statuses = Status.where(" name IN ('DC-PRINTED', 'HQ-PRINTED') ").map(&:status_id)
dispatch_statuses = Status.where(" name IN ('HQ-DISPATCHED') ").map(&:status_id)

births = PersonBirthDetail.where(" district_id_number IS NOT NULL ")

count = births.count
births.each_with_index do |birth, i|

  date = nil
  if !birth.source_id.blank? && birth.source_id.length > 19

    #Migrated From Old System
    remote_data = JSON.parse(`curl --silent http://192.168.48.2:5900/ebrs_hq/#{birth.source_id}`) rescue (puts "Missing for #{birth.source_id}")
    date        = remote_data['printed_at'].to_datetime rescue nil
    date_issued = remote_data['date_certificate_issued'].to_datetime rescue nil
    #puts "R--##{date}##{date_issued}##{i}/#{count}"
    next if date.present? #Already loaded
  end

  if date.blank?
    local_date = PersonRecordStatus.where(" status_id IN (#{print_statuses.join(',')}) AND person_id = #{birth.person_id} ").first
    local_issue_date = PersonRecordStatus.where(" status_id IN (#{dispatch_statuses.join(',')}) AND person_id = #{birth.person_id}").first

    date          = local_date.created_at.to_datetime rescue nil
    date_issued   = local_issue_date.to_datetime rescue nil
    puts "L--##{date}##{date_issued}##{i}/#{count}"
  end

  if !date.blank?
    certificate                 = Certificate.where(person_id: birth.person_id).first
    certificate                 = Certificate.new if certificate.blank?
    certificate.person_id       = birth.person_id
    certificate.date_printed    = date
    certificate.date_dispatched = date_issued
    certificate.save
  end

end

