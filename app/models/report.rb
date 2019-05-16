class Report < ActiveRecord::Base
  def self.births_report(params)
    start_date = params[:start_date].to_date.to_s rescue Date.today.to_s
    end_date = params[:end_date].to_date.to_s rescue Date.today.to_s

    if params[:status].blank?
      status = "Reported"
      status_ids = Status.all.map{|m| m.status_id}.join(",")
    else
      status = params[:status]
      status_ids = Status.where(name: status).map{|m| m.status_id}.join(",")
    end

    if params[:district].present?
       locations = Location.find(params[:district]).children << Location.find(params[:district]).id
    else
      locations = []
    end

    age_sql = ""
    if params[:operator].present?
        case params[:operator]
        when "BETWEEN"
            age_sql = " AND (DATEDIFF(NOW(),p.birthdate)/365) >= #{params[:start_age]} AND (DATEDIFF(NOW(),p.birthdate)/365) <= #{params[:end_age]} "
        else
            age_sql = " AND (DATEDIFF(NOW(),p.birthdate)/365) #{params[:operator]} #{params[:start_age]} "
        end
    end
    
    total_male   =  0
    total_female =  0

    reg_type = {}
    ['Normal', 'Abandoned', 'Adopted', 'Orphaned'].each do |type|
      reg_type[type] = {}
      
      male =  ActiveRecord::Base.connection.select_all(

            "SELECT COUNT(*) AS total FROM person_birth_details pbd
                  INNER JOIN person p ON p.person_id = pbd.person_id
                  INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                  INNER JOIN birth_registration_type t ON t.birth_registration_type_id = pbd.birth_registration_type_id AND t.name = '#{type}'
                WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
                AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
              "
      ).as_json.last['total'] rescue 0
      reg_type[type]['Male']  = male

      female =  ActiveRecord::Base.connection.select_all(

          "SELECT COUNT(*) AS total FROM person_birth_details pbd
                  INNER JOIN person p ON p.person_id = pbd.person_id
                  INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                  INNER JOIN birth_registration_type t ON t.birth_registration_type_id = pbd.birth_registration_type_id AND t.name = '#{type}'
                  WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
                  AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                  #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
              "
      ).as_json.last['total'] rescue 0
      reg_type[type]['Female'] = female

      total_male = total_male + male
      total_female = total_female + female
      
    end

    parents_married  = {}
    [0, 1].each do |k|
      parents_married[(k == 0 ? 'No' : 'Yes')] = {}
      parents_married[(k == 0 ? 'No' : 'Yes')]['Male'] =  ActiveRecord::Base.connection.select_all(

          "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}'
                    AND pbd.parents_married_to_each_other = #{k} AND p.gender = 'M'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.parents_married_to_each_other
                "
      ).as_json.last['total'] rescue 0
      parents_married[(k == 0 ? 'No' : 'Yes')]['Female'] =  ActiveRecord::Base.connection.select_all(

          "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}'
                    AND pbd.parents_married_to_each_other = #{k} AND p.gender = 'F'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.parents_married_to_each_other
                "
      ).as_json.last['total'] rescue 0
    end

    delayed = {}
    ['No', 'Yes'].each do |k|
      delayed[k] = {}
      c = (k == 'Yes') ? '>' : '<='

      delayed[k]['Male'] =  ActiveRecord::Base.connection.select_all(
          "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                  WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
                  AND DATEDIFF(pbd.date_registered, p.birthdate) #{c} 42
                  AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                  #{age_sql}
                "
      ).as_json.last['total'] rescue 0

      delayed[k]['Female'] =  ActiveRecord::Base.connection.select_all(
          "SELECT COUNT(*) AS total, p.gender FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                  WHERE DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
                  AND DATEDIFF(pbd.date_registered, p.birthdate) #{c} 42
                  AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                  #{age_sql}
                "
      ).as_json.last['total'] rescue 0
    end

    place_of_birth = {}

    ['Home','Hospital','Other'].each do |k|
        place_of_birth[k] = {}
        
        male =  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                      INNER JOIN person p ON p.person_id = pbd.person_id
                      INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.place_of_birth = (SELECT location_id FROM location WHERE name = '#{k}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0
        place_of_birth[k]['Male']  = male

        female=  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.place_of_birth = (SELECT location_id FROM location WHERE name = '#{k}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0
        place_of_birth[k]['Female']  = female

    end
    type_of_birth = {}
    ["Single","First Twin","Second Twin","First Triplet","Second Triplet", "Third Triplet","Other"].each do |type|
       type_of_birth[type] = {}
       male =  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.type_of_birth = (SELECT person_type_of_birth_id FROM person_type_of_births WHERE name = '#{type}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0

        type_of_birth[type]["Male"] = male

        female=  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.type_of_birth = (SELECT person_type_of_birth_id FROM person_type_of_births WHERE name = '#{type}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0
        type_of_birth[type]["Female"] = female
    end
    mode_of_delivery = {}
    ["SVD","Vacuum Extraction","Breech","Forceps","Caesarean Section"].each do |mode|
      mode_of_delivery[mode] = {}
      male =  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.mode_of_delivery_id = (SELECT mode_of_delivery_id FROM mode_of_delivery WHERE name = '#{mode}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'M'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0

        mode_of_delivery[mode]["Male"] = male
        
        female=  ActiveRecord::Base.connection.select_all(

                "SELECT COUNT(*) AS total FROM person_birth_details pbd
                    INNER JOIN person p ON p.person_id = pbd.person_id
                    INNER JOIN person_record_statuses prs ON prs.person_id = p.person_id AND prs.voided = 0
                    WHERE  pbd.mode_of_delivery_id = (SELECT mode_of_delivery_id FROM mode_of_delivery WHERE name = '#{mode}') AND DATE(pbd.date_registered) BETWEEN '#{start_date}' AND '#{end_date}' AND p.gender = 'F'
                    AND prs.status_id IN (#{status_ids}) #{locations.present? ? ' AND pbd.location_created_at IN('+locations.join(',')+')' : ''}
                    #{age_sql} GROUP BY p.gender, pbd.birth_registration_type_id
                  "
        ).as_json.last['total'] rescue 0
        mode_of_delivery[mode]["Female"] = female
    end

    total = {"Total" =>{"Male" => total_male, "Female" => total_female}}.as_json
    data = {
      'Registration Types' => reg_type.as_json,
      'Parents Married'    => parents_married.as_json,
      'Delayed Registrations' => delayed.as_json,
      'Place of Birth' => place_of_birth.as_json,
      'Type of Birth'  => type_of_birth.as_json,
      'Mode of Delivery'  => mode_of_delivery.as_json,
      "#{status}" => total.as_json
     }
    data
  end
  def self.by_status(status, start_date,end_date)
    

  end

  def self.user_audits(user = nil ,person = nil, start_date =nil,end_date = nil)

      start_date = Date.today.strftime('%Y-%m-%d 00:00:00') if start_date.blank?
      end_date = Date.today.strftime('%Y-%m-%d 23:59:59') if end_date.blank?


      query = "SELECT CONCAT(first_name,\" \", last_name) as name,username, table_name, comment, 
              (SELECT CONCAT(first_name, \" \", last_name) FROM person_name a 
              WHERE a.person_id = audit_trails.person_id AND a.voided =0) as client,
              (SELECT name FROM location l WHERE l.location_id = audit_trails.location_id) 
              as location,DATE_FORMAT(audit_trails.created_at,\"%Y-%m-%d %H:%i:%s\")as created_at,
              audit_trails.mac_address, audit_trails.ip_address FROM audit_trails 
              INNER JOIN person_name ON audit_trails.creator = person_name.person_id
              INNER JOIN users ON users.user_id = audit_trails.creator WHERE 
              DATE(audit_trails.created_at) >=  '#{start_date}' AND DATE(audit_trails.created_at) <= '#{end_date}' 
              ORDER BY audit_trails.created_at"

      return ActiveRecord::Base.connection.select_all(query).as_json
  end

  def self.dispatch_note(start_date, end_date)
    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day
    d_id = Status.where(name: "HQ-DISPATCHED").first.id

    @data = []
    PersonRecordStatus.find_by_sql("
        SELECT count(*) c, s.creator, s.created_at, u.username, n.first_name, n.last_name, d.location_created_at FROM person_record_statuses s
          LEFT JOIN users u ON u.user_id = s.creator AND s.status_id = #{d_id}
          INNER JOIN person_birth_details d ON d.person_id = s.person_id
          INNER JOIN person_name n ON u.person_id = n.person_id
          WHERE  s.created_at BETWEEN '#{start_date.to_s(:db)}' AND '#{end_date.to_s(:db)}'
          GROUP BY s.created_at, s.creator
          ORDER BY s.created_at DESC
      ").each do |s|
      @data << {
          'count'    => s.c,
          'datetime' => s.created_at.strftime("%d/%b/%Y  %H:%M:%S"),
          'creator'  => s.creator,
          'user'     => s.username,
          'district' => Location.find(s.location_created_at).district,
          'user_names' => (s.first_name + " " + s.last_name)
      }
    end

    @data
  end

  def self.dispatched_records(date, start_date, end_date)
    start_date = start_date.to_datetime.beginning_of_day rescue nil
    end_date = end_date.to_datetime.end_of_day rescue nil

    d_id = Status.where(name: "HQ-DISPATCHED").first.id

    ids = []
    if !date.blank?
      ids = PersonRecordStatus.where(" created_at = '#{date.to_datetime.to_s(:db)}' AND status_id = #{d_id}").map(&:person_id)
    else
      ids = PersonRecordStatus.where(" created_at BETWEEN '#{start_date.to_datetime.to_s(:db)}'
              AND '#{end_date.to_datetime.to_s(:db)}' AND status_id = #{d_id}").map(&:person_id)
    end

    ids
  end

  def self.general_report(start_date, end_date, location_ids)
    {
        [1, "Total Births Entered in eBRS"] => self.total(start_date, end_date, location_ids),
        [2, "Reported Births"] => self.reported(start_date, end_date, location_ids),
        [3, "Registered Births"] => self.registered(start_date, end_date, location_ids),
        [4, "Late Registrations"] => self.late_registrations(start_date, end_date, location_ids),
        [5, "Ammendments"] => self.ammendments(start_date, end_date, location_ids),
        [6, "Duplicates"] => self.duplicates(start_date, end_date, location_ids),
        [7, "Incomplete"] => self.incomplete(start_date, end_date, location_ids),
        [8, "Received By DV"] => self.received_by_dv(start_date, end_date, location_ids),
        [9, "Approved By DV"] => self.approved_by_dv(start_date, end_date, location_ids),
        [10, "Approved By DM"] => self.approved_by_dm(start_date, end_date, location_ids),
        [11, "Printed"] => self.printed(start_date, end_date, location_ids),
        [12, "Dispatched"] => self.dispatched(start_date, end_date, location_ids),
        [13, "Special Cases Reported"] => self.special_cases_reported([], start_date, end_date, location_ids),
        [14, "Special Cases Printed"] => self.special_cases_printed([], start_date, end_date, location_ids),
        [15, "Adopted Cases Reported"] => self.special_cases_reported(["Adopted"], start_date, end_date, location_ids),
        [16, "Adopted Cases Printed"] => self.special_cases_printed(["Adopted"], start_date, end_date, location_ids),
        [17, "Orphaned Cases Reported"] => self.special_cases_reported(["Orphaned"], start_date, end_date, location_ids),
        [18, "Orphaned Cases Printed"] => self.special_cases_printed(["Orphaned"], start_date, end_date, location_ids),
        [19, "Abandoned Cases Reported"] => self.special_cases_reported(["Abandoned"], start_date, end_date, location_ids),
        [20, "Abandoned Cases Printed"] => self.special_cases_printed(["Abandoned"], start_date, end_date, location_ids),
        [21, "Non Malawian Cases Reported"] => self.non_malawian_reported(start_date, end_date, location_ids),
        [22, "Non Malawian Cases Printed"] => self.non_malawian_printed(start_date, end_date, location_ids),
        [23, "Failed National ID Validations <small>(for >= 16 years)</small>"] => self.failed_validations(start_date, end_date, location_ids)

    }
  end

  def self.activity_audit_report(start_date, end_date, user_ids)

    results = []
    user_id_filter = ""
    if user_ids.blank?
      user_ids = UserRole.find_by_sql("
                SELECT ur.user_id FROM user_role ur
                  INNER JOIN role r ON r.role_id = ur.role_id
                WHERE r.level = 'HQ' AND r.role != 'Administrator'
              ").map(&:user_id)
    else
        user_ids = [user_ids.to_i]
    end

    user_id_filter = " AND prs.creator IN (#{user_ids.join(',')}) "

    data = PersonRecordStatus.find_by_sql(
        "SELECT prs.status_id, prs.created_at, prs.creator, prs.comments, birth.district_id_number,
        pn.first_name, pn.middle_name, pn.last_name FROM person_record_statuses prs
          INNER JOIN person_name pn ON pn.person_id = prs.person_id

          INNER JOIN person_birth_details birth ON birth.person_id = prs.person_id
        WHERE (DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}'  AND '#{end_date.to_date.to_s}') #{user_id_filter}
        ORDER BY prs.created_at DESC
        ")

    status_map          = Status.all.inject({}) { |r, d| r[d.id] = d.name; r }

    (data || []).each{|d|
      u = User.find(d.creator)

      results << [  u.username, u.name, d.district_id_number, "#{d.first_name} #{d.middle_name} #{d.last_name}",
                    d.created_at.to_datetime.strftime("%d/%b/%Y"), status_map[d.status_id], d.comments]
    }

    results
  end

  def self.total(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
        loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    PersonBirthDetail.where(" DATE(created_at) BETWEEN '#{start_date.to_date.to_s}'  AND '#{end_date.to_date.to_s}'
    AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count
  end

  def self.reported(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    PersonBirthDetail.where(" DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
      AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count
  end


  def self.registered(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    PersonBirthDetail.where(" DATE(date_registered) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
      AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count
  end

  def self.late_registrations(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person  p ON p.person_id = d.person_id
      WHERE DATE(d.date_reported) BETWEEN '#{start_date.to_date.to_s}'
        AND '#{end_date.to_date.to_s}' AND ABS(TIMESTAMPDIFF(DAY, d.date_reported, p.birthdate)) > 42
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        #{loc_query} ").count
  end

  def self.ammendments(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" (name RLIKE 'AMEND' OR name RLIKE 'AMMEND') AND name NOT RLIKE 'DC-' ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.duplicates(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name RLIKE 'DUPLICATE' AND name NOT RLIKE 'DC-' AND name NOT RLIKE 'FC-' ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.incomplete(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" (name RLIKE 'INCOMPLETE' OR name RLIKE 'CONFLICT') AND name NOT RLIKE 'DC-' AND name NOT RLIKE 'FC-' ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.approved_by_dv(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name = 'HQ-COMPLETE' ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.approved_by_dm(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name = 'HQ-CAN-PRINT' ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.printed(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name IN ('DC-PRINTED', 'HQ-PRINTED', 'HQ-DISPATCHED') ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.dispatched(start_date, end_date, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name IN ('HQ-DISPATCHED') ").map(&:status_id)

    PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
        AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end

  def self.special_cases_reported(type, start_date, end_date, location_ids=[])

    type_ids = BirthRegistrationType.all.collect{|b| b.id} if type.blank?
    type_ids = BirthRegistrationType.where(" name IN ('#{type.join("','")}') ").collect{|b| b.id} if !type.blank?
    type_ids = type_ids - [BirthRegistrationType.where(name: "Normal").first.id]

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    PersonBirthDetail.where(" DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
      AND birth_registration_type_id IN (#{type_ids.join(', ')})
      AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count
  end

  def self.special_cases_printed(type, start_date, end_date, location_ids=[])

    type_ids = BirthRegistrationType.all.collect{|b| b.id} if type.blank?
    type_ids = BirthRegistrationType.where(" name IN ('#{type.join("','")}') ").collect{|b| b.id} if !type.blank?
    type_ids = type_ids - [BirthRegistrationType.where(name: "Normal").first.id]

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    status_ids = Status.where(" name IN ('HQ-PRINTED', 'HQ-DISPATCHED') ").map(&:status_id)
    PersonBirthDetail.find_by_sql("SELECT d.person_id FROM person_birth_details d
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
      WHERE DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND birth_registration_type_id IN (#{type_ids.join(', ')})
        AND prs.status_id IN (#{status_ids.join(', ')})
        AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count
  end

  def self.non_malawian_reported(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    mother_type_id = PersonRelationType.where(name: "Mother").first.id
    father_type_id = PersonRelationType.where(name: "Father").first.id
    malawi_id = Location.where(name: "Malawi").first.id

    PersonBirthDetail.find_by_sql("SELECT d.person_id FROM person_birth_details d
      LEFT JOIN person_relationship mr ON d.person_id = mr.person_a AND mr.person_relationship_type_id = #{mother_type_id}
      LEFT JOIN person_relationship fr ON d.person_id = fr.person_a AND fr.person_relationship_type_id = #{father_type_id}
      LEFT JOIN person_addresses m_adr ON mr.person_b = m_adr.person_id
      LEFT JOIN person_addresses f_adr ON fr.person_b = f_adr.person_id
      WHERE DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND m_adr.citizenship != #{malawi_id} AND COALESCE(f_adr.citizenship, -1) != #{malawi_id}
        AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query}
      GROUP BY d.person_id ").count
  end

  def self.non_malawian_printed(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    mother_type_id = PersonRelationType.where(name: "Mother").first.id
    father_type_id = PersonRelationType.where(name: "Father").first.id
    malawi_id = Location.where(name: "Malawi").first.id
    status_ids = Status.where(" name IN ('HQ-PRINTED', 'HQ-DISPATCHED') ").map(&:status_id)

    PersonBirthDetail.find_by_sql("SELECT d.person_id FROM person_birth_details d
      LEFT JOIN person_relationship mr ON d.person_id = mr.person_a AND mr.person_relationship_type_id = #{mother_type_id}
      LEFT JOIN person_relationship fr ON d.person_id = fr.person_a AND fr.person_relationship_type_id = #{father_type_id}
      LEFT JOIN person_addresses m_adr ON mr.person_b = m_adr.person_id
      LEFT JOIN person_addresses f_adr ON fr.person_b = f_adr.person_id
      INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id AND prs.status_id IN (#{status_ids.join(', ')})
      WHERE DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND m_adr.citizenship != #{malawi_id} AND COALESCE(f_adr.citizenship, -1) != #{malawi_id}
        AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query}
      GROUP BY d.person_id ").count
  end

  def self.received_by_dv(start_date, end_date, location_ids=[])
        loc_query = ""
        if !location_ids.blank?
              loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
        end

        status_ids = Status.where(" name = 'HQ-ACTIVE' ").map(&:status_id)

        PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
     INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
     WHERE DATE(prs.created_at) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
       AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
       AND prs.status_id IN (#{status_ids.join(', ')})
        #{loc_query}  GROUP BY d.person_id").count
  end


  def self.failed_validations(start_date, end_date, location_ids=[])

    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

     PersonBirthDetail.find_by_sql("SELECT d.person_id FROM person_birth_details d
      INNER JOIN nid_verification_data v ON v.person_id = d.person_id
      WHERE DATE(date_reported) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
        AND v.passed = 0
        AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query}
      GROUP BY d.person_id ").count
  end


  def self.by_place_of_birth(start_date, end_date, place_of_birth, location_ids=[])
    loc_query = ""
    if !location_ids.blank?
      loc_query = " AND location_created_at IN (#{location_ids.join(', ')}) "
    end

    place_of_birth_id = Location.find_by_name(place_of_birth).id

    PersonBirthDetail.where(" place_of_birth = #{place_of_birth_id}
      AND DATE(date_registered) BETWEEN '#{start_date.to_date.to_s}' AND '#{end_date.to_date.to_s}'
      AND (source_id IS NULL OR LENGTH(source_id) >  19) #{loc_query} ").count

  end

  def self.biweekly_report(start_date, end_date)
    results = {}

    district_tag_id = LocationTag.where(name: "District").first.id
    facility_tag_id = LocationTag.where(name: "Health Facility").first.id

    districts = LocationTagMap.find_by_sql(" SELECT m.location_id FROM location_tag_map m
                  INNER JOIN location l ON l.location_id = m.location_id AND l.parent_location IS NULL
                  WHERE m.location_tag_id = #{district_tag_id}").map(&:location_id)
    districts.each do |district_id|
      facilities = districts = LocationTagMap.find_by_sql(" SELECT m.location_id FROM location_tag_map m
                  INNER JOIN location l ON l.location_id = m.location_id AND l.parent_location = #{district_id}
                  WHERE m.location_tag_id = #{facility_tag_id}").map(&:location_id)

      all_district_locs = facilities + [district_id]
      district = Location.find(district_id).name
      results[district] = {}
      results[district]["facility_registered"]  = self.registered(start_date, end_date, facilities)
      results[district]["dro_registered"] = self.registered(start_date, end_date, [district_id])
      results[district]["printed"]  = self.printed(start_date, end_date, all_district_locs)
      results[district]["total_registered"]  = self.registered(start_date, end_date, all_district_locs)

      results[district]["cum_facility_registered"]  = self.registered("01-01-2000".to_date, end_date, facilities)
      results[district]["cum_dro_registered"] = self.registered("01-01-2000".to_date, end_date, [district_id])
      results[district]["cum_printed"]  = self.printed("01-01-2000".to_date, end_date, all_district_locs)
      results[district]["cum_total_registered"]  = self.registered("01-01-2000".to_date, end_date, all_district_locs)

      results[district]["registered_but_born_in_hospital"]  = self.by_place_of_birth(start_date, end_date, "Hospital", all_district_locs)
      results[district]["registered_but_born_in_home"]  = self.by_place_of_birth(start_date, end_date, 'Home', all_district_locs)
      results[district]["registered_but_born_in_other"]  = self.by_place_of_birth(start_date, end_date, 'Other', all_district_locs)

      results[district]["cum_registered_but_born_in_hospital"]  = self.by_place_of_birth("01-01-2000".to_date, end_date, "Hospital", all_district_locs)
      results[district]["cum_registered_but_born_in_home"]  = self.by_place_of_birth("01-01-2000".to_date, end_date, 'Home', all_district_locs)
      results[district]["cum_registered_but_born_in_other"]  = self.by_place_of_birth("01-01-2000".to_date, end_date, 'Other', all_district_locs)

    end

    results
  end
end
