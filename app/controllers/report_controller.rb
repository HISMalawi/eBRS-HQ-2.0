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
      p = r
      n = r.national_serial_number
      gender = r.gender == 'M' ? '2' : '1'
      n = n.to_s.rjust(12, '0')

      records << {
        registration_number: n.insert(n.length/2, gender),
        birth_entry_number: r.district_id_number,
        first_name: r.first_name,
        middle_name: r.middle_name,
        last_name: r.last_name,
        birthdate: r.birthdate.to_date.strftime('%d/%b/%Y'),
        gender: r.gender,
        date_reported: (r.date_reported.to_date.strftime('%d/%b/%Y') rescue ""),
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
    locations = [params[:location_id]]
    facility_tag_id = LocationTag.where(name: 'Health Facility').first.id rescue [-1]
    (Location.find_by_sql("SELECT l.location_id FROM location l
                            INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id = #{facility_tag_id}
                          WHERE l.parent_location = #{params[:location_id]}") || []).each {|l|
      locations << l.location_id
    }

    status_a = []; status_b=[];  #status_a = Record Current Status; status_b = Record Prrevious Status
    case params[:cat]
      when 'voided_records'
        status_a = ['HQ-VOIDED']
        status_b = []
      when 'printed_certificates'
        status_a = ['HQ-PRINTED', 'HQ-DISPATCHED', 'HQ-RE-OPENED', 'HQ-CAN-RE-PRINT', 'DC-AMEND', 'DC-LOST', 'DC-DAMAGED']
        status_b = []
      when 'reported_births'
        status_a = Status.where(" name RLIKE 'HQ' ").map(&:name) + (['DC-LOST', 'DC-DAMAGED', 'DC-AMEND', 'DC-RE-OPENED', 'DC-ASK']) -
            ['HQ-VOIDED', 'HQ-VOIDED DUPLICATE']
        status_b = []
      when 'registered_births'
        status_a = ['HQ-PRINTED', 'HQ-DISPATCHED', 'HQ-RE-OPENED', 'HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT', 'DC-AMEND', 'DC-LOST', 'DC-DAMAGED']
        status_b = []
      when 'all'
        status_a = []
        status_b = []
    end

    s1        = Status.where("name IN ('#{status_a.join("',  '")}')").map(&:status_id) rescue nil
    s1        = Status.pluck("status_id") if s1.blank?

    s2        = Status.where("name IN ('#{status_b.join("',  '")}')").map(&:status_id) rescue nil
    s2        = Status.pluck("status_id") if s2.blank?

    start_date        = params[:start_date].to_date.strftime('%Y-%m-%d 00:00:00')
    end_date          = params[:end_date].to_date.strftime('%Y-%m-%d 23:59:59')
    status_map = Status.all.inject({}){|h, s| h[s.status_id] = s.name; h}

    data = Person.find_by_sql(["
            SELECT p.birthdate, p.gender, n.first_name f_n, n.last_name l_n, n.middle_name m_n, d.*, s1.status_id FROM person p
              INNER JOIN person_birth_details d ON d.person_id = p.person_id
              INNER JOIN person_name n ON n.person_id = p.person_id
              INNER JOIN person_record_statuses s1 ON s1.person_id = p.person_id AND  s1.voided = 0
              INNER JOIN person_record_statuses s2 ON s2.person_id = p.person_id
              WHERE s1.status_id IN (#{s1.join(', ')}) AND s2.status_id IN (#{s2.join(', ')})
                AND d.location_created_at IN (#{locations.join(', ')}) AND d.date_reported BETWEEN ? AND ?
              GROUP BY p.person_id
            ", start_date, end_date])

    records = []
    (data || []).each do |r|
      p = r

      n = r.national_serial_number
      gender = r.gender == 'M' ? '2' : '1'
      n = n.to_s.rjust(12, '0')

      records << [
        (r.national_serial_number.blank? ? "" : (n.insert(n.length/2, gender))),
        r.district_id_number,
        p.f_n,
        p.m_n,
        p.l_n,
        r.birthdate.to_date.strftime('%d/%b/%Y'),
        {'2' => 'Male', '1' => 'Female'}[gender],
        status_map[p.status_id],
        (p.date_reported.to_date.strftime("%d/%b/%Y") rescue nil)
      ]
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
      p = r

      n = r.national_serial_number
      gender = r.gender == 'M' ? '2' : '1'
      n = n.to_s.rjust(12, '0')

      records << {
        registration_number: n.insert(n.length/2, gender),
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

    data = ActiveRecord::Base.connection.select_all("SELECT person.gender, person.birthdate dob, n.*, d.*, s.created_at AS date_of_status, s.* FROM person
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
      records << [
          r['national_serial_number'],
          r['district_id_number'],
          r['first_name'],
          r['middle_name'],
          r['last_name'],
          r['dob'].to_date.strftime('%d/%b/%Y'),
          {'M' => 'Male', 'F' => 'Female'}[r['gender']],
          r['date_of_status'].to_date.strftime('%d/%b/%Y'),
      ]
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

  def reg_vs_birth_district
    tag_id = LocationTag.where(name: "District").last.id
    start_date = params[:start_date].to_date rescue "2000-01-01".to_date
    end_date = params[:end_date].to_date rescue Date.today.to_date

    @data = {}
    code_map = {}
    @districts = Location.find_by_sql(" SELECT l.location_id, l.name, l.code FROM location l
                  INNER JOIN location_tag_map m ON m.location_id = l.location_id
                    WHERE location_tag_id = #{tag_id} AND parent_location IS NULL")
    .map{|l| [l.location_id, l.name, l.code]}

    @districts.each do |d|
      code_map[d[0]] = d[2]
    end

    session[:code_map] = code_map

    @columns = @districts.collect{|d| d[2]}.sort
    #primary_d   = District Of Registration
    #secondary_d = District of Birth

    @districts.each do |primary_d|
      district_plus_facilities = [primary_d[0]] + (Location.find_by_sql(" SELECT location_id FROM location WHERE parent_location = #{primary_d[0]} ").map(&:location_id))

      break_down = PersonBirthDetail.find_by_sql("
        SELECT COUNT(*) total, district_of_birth FROM person_birth_details
          WHERE district_id_number IS NOT NULL
            AND location_created_at IN (#{district_plus_facilities.join(', ')})
            AND (DATE(created_at) BETWEEN '#{start_date.to_s(:db)}' AND '#{end_date.to_s(:db)}')
          GROUP BY district_of_birth
        ")

      break_down.each do |secondary_d|
        @data[primary_d[2]] = {} if @data[primary_d[2]].blank?
        @data[primary_d[2]][code_map[secondary_d['district_of_birth'].to_i]] = secondary_d['total'].to_i
      end
    end
  end

  def crossmatch
    code_map = session[:code_map].invert
    reg_district = code_map[params[:reg_code]]
    birth_district = code_map[params[:birth_code]]
    if params[:draw].blank?

    else

      reg_facilities = [reg_district] + (Location.find_by_sql(" SELECT location_id FROM location WHERE parent_location = #{reg_district} ").map(&:location_id))
      data = PersonService.query_for_crossmatch(birth_district, reg_facilities, params[:start_date].to_date.to_s, params[:end_date].to_date.to_s, params)

      render :text => data.to_json and return
    end

    render :layout => "viewport"
  end

  def dispatches
    start_date = params[:start_date].to_date rescue "2018-06-11".to_date
    end_date = params[:end_date].to_date rescue Date.today.to_date
    d_id = Status.where(name: "HQ-DISPATCHED").first.id
    @available_printers = SETTINGS["printer_name"].split('|')

    @data = []
    PersonRecordStatus.find_by_sql("
        SELECT count(*) c, s.creator, s.created_at, u.username, n.first_name, n.last_name, d.location_created_at FROM person_record_statuses s
          INNER JOIN users u ON u.user_id = s.creator AND s.status_id = #{d_id}
          INNER JOIN person_birth_details d ON d.person_id = s.person_id
          INNER JOIN person_name n ON u.person_id = n.person_id
          WHERE  DATE(s.created_at) BETWEEN '#{start_date.to_s}' AND '#{end_date.to_s}'
          GROUP BY s.created_at, s.creator
          ORDER BY s.created_at DESC LIMIT 1000
      ").each_with_index do |s, i|
      @data << {
          'index'    => (i + 1),
          'count'    => s.c,
          'datetime' => s.created_at.strftime("%d/%b/%Y  %H:%M:%S"),
          'creator'  => s.creator,
          'user'     => s.username,
          'district' => Location.find(s.location_created_at).district,
          'user_names' => (s.first_name + " " + s.last_name)
      }
    end
  end

  def view_dispatches
    path = "#{Rails.root}/public/#{Time.now.strftime("%Y%m%d%H%M%S")}.pdf"

    start_date = params[:start_date].to_datetime.strftime("%Y%m%d%H%M%S") rescue nil
    end_date   = params[:end_date].to_datetime.strftime("%Y%m%d%H%M%S") rescue nil
    date = params[:date].to_datetime.strftime("%Y%m%d%H%M%S") rescue nil

    url = URI.parse("http://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/report/dispatch_list?date=#{date}&start_date=#{start_date}&end_date=#{end_date}")
    cmd = "wkhtmltopdf 	--orientation landscape --page-size A4 '#{url}'  #{path}\n"

    t4 = Thread.new {
      Kernel.system(cmd)
      sleep(4)
      Kernel.system "lp -d #{params[:printer_name]} #{path}\n"
      sleep(5)
    }

    #@path = path
    #@file = File.read(path)

    #File.open(@path, 'r') do |f|
    #  send_data f.read.force_encoding('BINARY'), :filename => path, :type => "application/pdf", :disposition => "attachment"
    #end

    render :text => "done".to_json
  end

  def dispatch_list
    date = params[:date]

    if !date.blank?
      @records = Report.dispatched_records(params[:date], nil, nil).sort
    else
      @records = Report.dispatched_records(nil, params[:start_date], params[:end_date]).sort
    end

    person_ids = @records.join(', ')
    @people = Person.find_by_sql("SELECT n.*, p.gender, p.birthdate, d.national_serial_number, d.district_id_number, d.date_registered, d.location_created_at FROM person p
                                 INNER JOIN person_birth_details d ON d.person_id = p.person_id
                                 INNER JOIN person_name n ON n.person_id = p.person_id
                        WHERE d.person_id IN (#{person_ids}) ")
    @districts = []

    @data = []
    @people.each do |p|

      @districts <<  Location.find(@people.first.location_created_at).district
      details = PersonBirthDetail.where(:person_id => p.person_id).last

      @data << {
          'name'                => p.name,
          'brn'                 => details.brn,
          'ben'                 => details.ben,
          'dob'                 => p.birthdate.to_date.strftime('%d/%b/%Y'),
          'sex'                 => p.gender,
          'place_of_birth'      => details.birthplace,
          'date_registered'     => (p.date_registered.to_date.strftime('%d/%b/%Y') rescue nil)
      }
    end

    @districts = @districts.uniq
    @district = @districts.join(", ")

    render :layout => false
  end

  def general_report
    @districts = districts
  end

  def activity_audit
    @users = UserRole.find_by_sql("
                SELECT u.user_id, u.username, pn.first_name, pn.middle_name, pn.last_name FROM user_role ur
                  INNER JOIN role r ON r.role_id = ur.role_id
                  INNER JOIN users u ON u.user_id = ur.user_id
                  INNER JOIN person_name pn ON pn.person_id = u.person_id
                WHERE r.level = 'HQ' AND r.role != 'Administrator'
                ORDER BY pn.first_name, pn.middle_name, pn.last_name
              ").as_json
  end

  def general_report_query

    location_ids = []
    if !params[:district_id].blank?
      location_ids = [params[:district_id]]

      facility_tag_id = LocationTag.where(name: 'Health Facility').first.id rescue [-1]
      (Location.find_by_sql("SELECT l.location_id FROM location l
                            INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id = #{facility_tag_id}
                          WHERE l.parent_location = #{params[:district_id]}") || []).each {|l|
        location_ids << l.location_id
      }
    end

    data = Report.general_report(params[:start_date], params[:end_date], location_ids)

    render :text => data.to_json
  end

  def activity_audit_query

    data = Report.activity_audit_report(params[:start_date], params[:end_date], params[:user_id])
    render :text => data.to_json
  end


  def certificates

    if !params[:position].blank?
      certificates = []
      `ls -t #{SETTINGS['certificates_path']}`.split("\n").each{|c|
        certificates << [c, File.mtime("#{SETTINGS['certificates_path']}#{c}")]
      }

      certificates = certificates.each_slice(3).to_a[params[:position].to_i]

      render :text => certificates.to_json and return
    end

  end

  def certificate_pdf
    file = File.open("#{SETTINGS['certificates_path']}/#{params[:reference]}")
    send_file(file, :filename => params[:reference] , :disposition => 'inline', :type => "application/pdf")
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
  
