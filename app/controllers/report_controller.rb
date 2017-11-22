class ReportController < ApplicationController

  def printed_certificates
    @districts = districts
  end

  def get_printed_certificates
    locations = Location.where(parent_location: params[:location_id]) + [params[:location_id]]
    person_type       = PersonType.where(name: 'Client').first
    status_ids        = Status.where(name: ['HQ-DISPATCHED','HQ-PRINTED']).map(&:id)
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
     
    data = PersonBirthDetail.where("p.person_type_id = ? AND
      person_birth_details.location_created_at IN (?)
      AND s.status_id IN(?) AND date_reported BETWEEN ? AND ?",
      person_type.id, locations,
      status_ids, start_date, end_date).joins("INNER JOIN core_person p 
      ON person_birth_details.person_id = p.person_id
      INNER JOIN person ps
      ON ps.person_id = p.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = ps.person_id AND s.voided = 0").group('n.person_id')\
      .select("ps.*, n.*, person_birth_details.*").order('p.created_at DESC,
      district_id_number ASC')

    records = []
    (data || []).each do |r|
      records << {
        registration_number: r.national_serial_number,
        birth_entry_number: r.district_id_number,
        first_name: r.first_name,
        middle_name: r.middle_name,
        last_name: r.last_name,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: r.gender,
        date_reported: r.date_reported.to_date.strftime('%d/%b/%Y'),
        person_id: r.person_id
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
    #    status_ids        = Status.where(name: 'HQ-APPROVED').first.id
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
     
    data = Person.where("national_serial_number IS NOT NULL AND p.person_type_id = ? AND
      LEFT(district_id_number, #{district_code_len}) = ?
       AND s.created_at BETWEEN ? AND ?",
      person_type.id, district_code,
      start_date, end_date).joins("INNER JOIN core_person p
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d 
      ON d.person_id = person.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s 
      ON s.person_id = person.person_id AND s.voided = 0").group('n.person_id')\
      .select("person.*, n.first_name f_n, n.last_name l_n, n.middle_name m_n, d.*, s.created_at dispatch_date").order('p.created_at DESC,
      district_id_number ASC')

    records = []
    (data || []).each do |r|
      p = r

      n = r.national_serial_number
      gender = r.gender == 'M' ? '2' : '1'
      n = n.to_s.rjust(12, '0')

      records << {
        registration_number: n.insert(n.length/2, gender),
        birth_entry_number: r.district_id_number,
        first_name: p.f_n,
        middle_name: p.m_n,
        last_name: p.l_n,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: {'2' => 'Male', '1' => 'Female'}[gender],
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

  def record_state_and_date
    @statuses = Status.all.order("name").reverse
  end

  def ajax_record_state_and_date
    person_type       = PersonType.where(name: 'Client').first.id
    status_id        = params[:status]
    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')

    data = ActiveRecord::Base.connection.select_all("SELECT person.*, n.*, d.*, s.created_at AS date_of_status, s.* FROM person
      INNER JOIN core_person p
      ON person.person_id = p.person_id
      INNER JOIN person_birth_details d ON d.person_id = person.person_id
      INNER JOIN person_name n ON n.person_id = p.person_id
      INNER JOIN person_record_statuses s ON s.person_id = person.person_id AND s.voided = 0
      WHERE p.person_type_id = #{person_type}
        AND s.status_id = '#{status_id}' AND s.created_at BETWEEN '#{start_date}' AND '#{end_date}'
         GROUP BY n.person_id ORDER By s.created_at, district_id_number")

    records = []
    (data || []).each do |r|
      p = Person.find(r['person_id'])
      records << {
          registration_number: r['national_serial_number'],
          birth_entry_number: r['district_id_number'],
          first_name: r['first_name'],
          middle_name: r['middle_name'],
          last_name: r['last_name'],
          birthdate: p.birthdate.to_date.strftime('%d/%b/%Y'),
          gender: p.full_gender,
          date: r['date_of_status'].to_date.strftime('%d/%b/%Y'),
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
  
