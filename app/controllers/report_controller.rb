class ReportController < ApplicationController

  def printed_certificates
    @districts = districts
  end

  def get_printed_certificates
    district_code     = Location.find(params[:location_id]).code
    district_code_len = district_code.length
    person_type       = PersonType.where(name: 'Client').first
    status_ids        = Status.where(name: ['HQ-DISPATCHED','HQ-PRINTED']).map(&id)
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
     
    data = Person.where("p.person_type_id = ? AND 
      LEFT(district_id_number, #{district_code_len}) = ?
      AND s.status_id IN(?) AND s.created_at BETWEEN ? AND ?", 
      person_type.id, district_code,
      status_ids, start_date, end_date).joins("INNER JOIN core_person p 
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('n.person_id')\
      .select("person.*, n.*, d.*, s.created_at dispatch_date").order('p.created_at DESC, 
      district_id_number ASC')

    records = []
    (data || []).each do |r|
      p = Person.find(r.person_id)
      records << {
        registration_number: r.national_serial_number,
        birth_entry_number: r.district_id_number,
        first_name: p.first_name,
        middle_name: p.middle_name,
        last_name: p.last_name,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: p.full_gender,
        dispatch_date: r.dispatch_date.to_date.strftime('%d/%b/%Y'),
        person_id: p.person_id
      }
    end

    render text: records.to_json
  end


  def reported_births
    @districts = districts
  end

  def get_reported_births
    district_code     = Location.find(params[:location_id]).code
    district_code_len = district_code.length
    person_type       = PersonType.where(name: 'Client').first
    status_id         = Status.where(name: 'HQ-ACTIVE').first.id
     
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')

    data = Person.where("p.person_type_id = ? AND 
      LEFT(district_id_number, #{district_code_len}) = ?
      AND status_id = ? AND s.created_at BETWEEN ? AND ?", 
      person_type.id, district_code,
      status_id, start_date, end_date).joins("INNER JOIN core_person p 
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('d.person_id')\
      .select("person.*, d.*, s.created_at dispatch_date").order('p.created_at DESC, 
      district_id_number ASC')

    records = {}
    (data || []).each do |r|
      p = Person.find(r.person_id)
      records[p.full_gender] = 0 if records[p.full_gender].blank?
      records[p.full_gender] += 1
    end

    render text: records.to_json
  end

  def approved_at_hq
    @districts = districts
  end

  def get_approved_at_hq
    district_code     = Location.find(params[:location_id]).code
    district_code_len = district_code.length
    person_type       = PersonType.where(name: 'Client').first
    status_ids        = Status.where(name: 'HQ-APPROVED').first.id
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
     
    data = Person.where("p.person_type_id = ? AND 
      LEFT(district_id_number, #{district_code_len}) = ?
      AND s.status_id IN(?) AND s.created_at BETWEEN ? AND ?", 
      person_type.id, district_code,
      status_ids, start_date, end_date).joins("INNER JOIN core_person p 
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('n.person_id')\
      .select("person.*, n.*, d.*, s.created_at dispatch_date").order('p.created_at DESC, 
      district_id_number ASC')

    records = []
    (data || []).each do |r|
      p = Person.find(r.person_id)
      records << {
        registration_number: r.national_serial_number,
        birth_entry_number: r.district_id_number,
        first_name: p.first_name,
        middle_name: p.middle_name,
        last_name: p.last_name,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: p.full_gender,
        person_id: p.person_id
      }
    end

    render text: records.to_json
  end

  def get_voided_records
    person_type       = PersonType.where(name: 'Client').first
    status_ids        = Status.where(name: 'HQ-VOIDED').first.id
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
     
    data = Person.where("p.person_type_id = ? AND 
      s.status_id IN(?) AND s.created_at BETWEEN ? AND ?", 
      person_type.id, status_ids, start_date, end_date)\
      .joins("INNER JOIN core_person p 
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('n.person_id')\
      .select("person.*, n.*, d.*, s.created_at dispatch_date").order('p.created_at DESC, 
      district_id_number ASC')

    records = []
    (data || []).each do |r|
      p = Person.find(r.person_id)
      records << {
        registration_number: r.national_serial_number,
        birth_entry_number: r.district_id_number,
        first_name: p.first_name,
        middle_name: p.middle_name,
        last_name: p.last_name,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: p.full_gender,
        person_id: p.person_id
      }
    end

    render text: records.to_json
  end

  def registered_births
    @districts = districts
  end

  def get_registered_births
    district_code     = Location.find(params[:location_id]).code
    district_code_len = district_code.length
    person_type       = PersonType.where(name: 'Client').first
    status_id         = Status.where(name: 'DC-ACTIVE').first.id
     
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')

    data = Person.where("p.person_type_id = ? AND 
      LEFT(district_id_number, #{district_code_len}) = ?
      AND status_id = ? AND s.created_at BETWEEN ? AND ?", 
      person_type.id, district_code,
      status_id, start_date, end_date).joins("INNER JOIN core_person p 
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('d.person_id')\
      .select("person.*, d.*, s.created_at dispatch_date").order('p.created_at DESC, 
      district_id_number ASC')

    records = {}
    (data || []).each do |r|
      p = Person.find(r.person_id)
      records[p.full_gender] = 0 if records[p.full_gender].blank?
      records[p.full_gender] += 1
    end

    render text: records.to_json
  end

  def get_user_audit_trail
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00') rescue nil
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59') rescue nil

    records = Report.user_audits(nil,nil,start_date,end_date)

    render text: records.to_json
  end

  def birth_reports
    @districts = districts
    @statuses = Status.all.map(&:name)
    @data = Report.births_report(params)
  end

  private

  def districts
    location_tag = LocationTag.where(name: 'District').first

    @districts = Location.group("location.location_id").where("t.location_tag_id = ?
      AND location.name NOT LIKE (?)", location_tag.id, 
      "%city%").joins("INNER JOIN location_tag_map m 
      ON m.location_id = location.location_id
      INNER JOIN location_tag t 
      ON t.location_tag_id = m.location_tag_id").order("location.name ASC")

  end

end
  
