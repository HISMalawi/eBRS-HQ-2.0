class PersonRecordStatus < ActiveRecord::Base
    self.table_name = :person_record_statuses
    self.primary_key = :person_record_status_id
    include EbrsAttribute

    belongs_to :person, foreign_key: "person_id"
    belongs_to :status, foreign_key: "status_id"
    #after_create :run_notification_hooks

    def self.new_record_state(person_id, state, change_reason='', user_id=nil)
      status = nil

        begin
         ActiveRecord::Base.transaction do
          user_id = User.current.id rescue nil if user_id.blank?
          user_id = User.find_by_username("admin279").id if user_id.blank?
          state_id = Status.where(:name => state).first.id
          trail = self.where(:person_id => person_id, :voided => 0)

          trail.each do |state|
            state.update_attributes(
                voided: 1,
                date_voided: Time.now,
                voided_by: user_id
            )
          end


          status = PersonRecordStatus.new(
              person_id: person_id,
              status_id: state_id,
              voided: 0,
              creator: user_id,
              comments: change_reason
          )

          status.save

          birth_details = PersonBirthDetail.where(person_id: person_id).last
          person = Person.find(person_id)
          national_id = person.id_number

          if ['HQ-COMPLETE'].include?(state) && !national_id.blank?
            NIDValidator.validate(person, national_id)
          end

          if ['HQ-CAN-PRINT', 'HQ-CAN-RE-PRINT'].include?(state) && birth_details.national_serial_number.blank?
              birth_details.generate_brn

              allocation = IdentifierAllocationQueue.new
              allocation.person_id = person_id
              allocation.assigned = 0
              allocation.creator = User.current.id
              allocation.person_identifier_type_id = PersonIdentifierType.where(:name => "National ID Number").last.person_identifier_type_id
              allocation.created_at = Time.now
              allocation.save
          end
        end
      rescue StandardError => e
           self.log_error(e.message,person_id)
      end

		return status
  end

  def self.status(person_id)
    self.where(:person_id => person_id).order("created_at, person_record_status_id").last.status.name rescue nil
  end

  def run_notification_hooks
    level = SETTINGS['application_mode']
    level = 'HQ' if level.blank?

    ntype = NotificationType.where(trigger_status_id: self.status_id).first rescue nil
    if ntype.present?
      Notification.create(
        notification_type_id: ntype.id,
        person_id: self.person_id,
        person_record_status_id: self.id,
        seen: 0
      )
    end
  end

  def self.log_error(error_msge, content)

      file_path = "#{Rails.root}/app/assets/data/error_log.txt"
      if !File.exists?(file_path)
             file = File.new(file_path, 'w')
      else
         File.open(file_path, 'a') do |f|
            f.puts "#{error_msge} >>>>>> #{content}"
        end
      end

  end

  def self.stats(types=['Normal', 'Adopted', 'Orphaned', 'Abandoned'], approved=true, locations = [])
    if locations.length > 0 || types.length != 4

      status_map          = Status.all.inject({}) { |r, d| r[d.id] = d.name; r }
      result = Status.all.inject({}) { |r, d| r[d.name] = 0; r }

      birth_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]
      loc_str = ""
      if !locations.blank?
        loc_str = " AND p.location_created_at IN (#{locations.join(', ')})"
      end

      PersonRecordStatus.find_by_sql("
        SELECT s.status_id, COUNT(*) c FROM person_record_statuses s
          INNER JOIN person_birth_details p ON p.person_id = s.person_id AND p.birth_registration_type_id IN (#{birth_type_ids.join(', ')})
          WHERE s.voided = 0 #{loc_str}
          GROUP BY s.status_id
      ").each do |row|
        result[status_map[row['status_id']]] = row['c']
      end

      unless approved == false
        excluded_states = ['HQ-REJECTED', 'HQ-VOIDED', 'HQ-PRINTED', 'HQ-DISPATCHED'].collect{|s| Status.find_by_name(s).id}
        included_states = Status.where("name like 'HQ-%' ").map(&:status_id)

        result['APPROVED BY ADR'] =  self.find_by_sql("
      SELECT COUNT(*) c FROM person_record_statuses
      WHERE voided = 0 AND status_id NOT IN (#{excluded_states.join(', ')}) AND status_id IN (#{included_states.join(', ')})")[0]['c']
      end

      return result
    else
      return JSON.parse(File.read("#{Rails.root}/stats.json"))
    end
  end

    def self.had_stats(state, role=nil)
      result = Status.all.inject({}){|r, c| r[c.name] = 0; r}
      status_map          = Status.all.inject({}) { |r, d| r[d.id] = d.name; r }

      if role.blank?
        user_ids = User.pluck("user_id")
      else
        user_ids = UserRole.where(role_id: Role.where(role: role).last.id).map(&:user_id)
      end

      user_ids = [-1] if user_ids.blank?

      prev_status_ids = Status.where(" name IN ('#{state.split("|").join("', '")}')").map(&:status_id) + [-1]

      PersonRecordStatus.find_by_sql("
        SELECT s.status_id, COUNT(*) c FROM person_record_statuses s
          INNER JOIN person_record_statuses prev_s ON prev_s.person_id = s.person_id AND prev_s.status_id IN (#{prev_status_ids.join(', ')})
            AND prev_s.creator IN (#{user_ids.join(', ')})
          WHERE s.voided = 0
          GROUP BY s.status_id
      ").each do |row|
        result[status_map[row['name']]] = row['c']
      end

      result
    end

    def self.type_stats(states=nil, old_state=nil, old_state_creator=nil)
      result = {}
      return result if states.blank?
      had_query = ''

      if old_state.present?

        prev_status_ids = Status.where(" name IN ('#{old_state.split("|").join("', '")}')").map(&:status_id)
        had_query = "INNER JOIN person_record_statuses prev_s ON prev_s.person_id = s.person_id AND prev_s.status_id IN (#{prev_status_ids.join(', ')})"

        if old_state_creator.present?
          user_ids = UserRole.where(role_id: Role.where(role: old_state_creator).last.id).map(&:user_id)
          user_ids = [-1] if user_ids.blank?

          had_query += " AND prev_s.creator IN (#{user_ids.join(', ')})"
        end
      end

      status_ids = states.collect{|s| Status.where(name: s).last.id} rescue Status.all.map(&:status_id)

      data = self.find_by_sql("
      SELECT t.name, COUNT(*) c FROM person_birth_details d
        INNER JOIN person_record_statuses s ON d.person_id = s.person_id
        INNER JOIN birth_registration_type t ON t.birth_registration_type_id = d.birth_registration_type_id
          #{had_query}
        WHERE s.voided = 0 AND s.status_id IN (#{status_ids.join(', ')}) GROUP BY d.birth_registration_type_id")

      (data || []).each do |r|
        result[r['name']] = r['c']
      end
      result
    end

   def self.trace_data(person_id)
    return [] if person_id.blank?
    result = []
    PersonRecordStatus.where(person_id: person_id).order("created_at DESC").each do |status|
      user = User.find(status.creator) rescue nil
			action = "Status changed to:  '#{status.status.name.titleize.gsub(/^Hq/, "HQ").gsub(/^Dc/, 'DC').gsub(/^Fc/, 'FC')}'"
			if status.status.name.upcase == "DC-ACTIVE"
				action  = "New Record Created"
			elsif status.status.name.upcase == "HQ-ACTIVE" && user.user_role.role.role == "ADR"
				action = "Record Approved By ADR"
			end

      result << {
          "date" => status.created_at.strftime("%d-%b-%Y"),
          "time" => status.created_at.strftime("%I:%M %p"),
          "site" => (user.user_role.role.level rescue nil),
          "action" => action,
          "user"   => ("#{user.first_name} #{user.last_name} <br /> <span style='font-size: 0.8em;'><i>(#{user.user_role.role.role})</i></span>" rescue ""),
          "comment" => status.comments
      }
    end

    result
   end

   def self.common_comments(roles="All", statuses = "All", user_id="All", limit=20)

     if roles == "All"
       roles = Role.all.map(&:role_id)
     else
       roles = roles.collect{|r| Role.where(role: r).first.id }
     end

     if statuses == "All"
        status_ids = Status.all.map(&:status_id)
     else
        status_ids = statuses.collect{|r| Status.where(name: r).first.status_id }
     end

      user_query = ""
     if user_id != "All"
       user_query = " AND prs.creator = #{user_id}"
     end

     PersonRecordStatus.find_by_sql("
      SELECT comments, count(*) total FROM person_record_statuses prs
        INNER JOIN users u ON u.user_id = prs.creator
        INNER JOIN user_role ur ON ur.user_id = u.user_id AND ur.role_id IN (#{roles.join(', ')})
        WHERE COALESCE(comments, '') != '' AND prs.status_id IN (#{status_ids.join(', ')}) #{user_query}
        GROUP BY comments  ORDER BY COUNT(*) DESC LIMIT #{limit};
    ").collect{|s| [s.comments, s.total]}
   end
end
