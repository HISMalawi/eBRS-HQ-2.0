class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  #protect_from_forgery	#with: :null_session

  before_filter :check_if_logged_in, :except => ['login', 'birth_certificate', 'dispatch_list', 'sync_status', 'check_print_rules', 'remote_nid_request']
  before_filter :check_pings, :except => ["sync_status", "remote_nid_request"]
  before_filter :check_couch_loading, :except => ["sync_status", "remote_nid_request"]
  before_filter :check_notifications, :except  => ["sync_status", "remote_nid_request"]

  def check_couch_loading
    last_run_time = File.mtime("#{Rails.root}/public/tap_sentinel").to_time rescue nil
    job_interval = 60
    now = Time.now
    if last_run_time.present? && (now - last_run_time).to_f > 2*job_interval
      Thread.new{
        RestClient.get("#{SETTINGS['ebrs_services_link']}/api/start_data_loading")
      }
    end
  end

	def check_pings
    last_run_time = File.mtime("#{Rails.root}/public/ping_sentinel").to_time rescue nil
    job_interval = 60
    now = Time.now
    if last_run_time.present? && (now - last_run_time).to_f > 7*job_interval
      Thread.new{
        RestClient.get("#{SETTINGS['ebrs_services_link']}/api/start_ping")
      }
    end
  end

  def icoFolder(required_image)

     case required_image.downcase

     when "icofolder"
     		return folder
     when "coa"
     		return coa
     when "search"
        return searchIcon
     end

  end

  def has_role(role)
    true
  end

  def application_mode
    if SETTINGS['application_mode'] == 'FC'
      return 'Facility'
    else
      return 'DC'
    end
  end

  def login!(user)
    session[:user_id] = user.id
    AuditTrail.ip_address_accessor = request.remote_ip
    AuditTrail.mac_address_accessor = ` arp #{request.remote_ip}`.split(/\n/).last.split(/\s+/)[2]
    AuditTrail.ip_address_accessor.inspect

    AuditTrail.create!(person_id: user.id,
                       audit_trail_type_id: AuditTrailType.find_by_name("SYSTEM").id,
                       comment: "User login")
  end

  def logout!
    AuditTrail.create(person_id: session[:user_id],
                       audit_trail_type_id: AuditTrailType.find_by_name("SYSTEM").id,
                       comment: "User logout") unless session[:user_id].blank?
    session[:user_id] = nil

  end

  def application_couchdb
     con = YAML.load_file(File.join(Rails.root, "config", "couchdb.yml"))
     return "#{con['prefix']}_#{con['suffix']}"
  end

  def admin?
    ApplicationController.helpers.admin?
  end

  def check_notifications

    @stats_time     = File.mtime("stats.json").to_pretty rescue ""
    if ((Time.now - File.mtime("stats.json")) / 60 > 3)
      #Rerun Query
      stats       = PersonRecordStatus.stats
      File.open("stats.json", 'w'){|f|
        f.write(stats.to_json)
      }
    end

    @nris_up        = File.read("#{Rails.root}/public/nris_status").to_s == "true"
    #@notifications = Notification.by_role(User.current.user_role.role_id) rescue nil
    @pending_nid_assignment = 0
    if User.current && User.current.user_role.role.role == "Data Manager"
      @pending_nid_assignment = IdentifierAllocationQueue.where(
          assigned: 0,
        person_identifier_type_id: PersonIdentifierType.where(:name => "National ID Number").last.person_identifier_type_id
      ).count
    end
  end

  private

  def check_if_logged_in

        if session[:user_id].blank?
      if request.filtered_parameters["action"] == 'create' and request.filtered_parameters["controller"] == 'logins'
        return
      end

      redirect_to '/login' and return
    else

      user = User.find(session[:user_id]) rescue nil

      if user.blank?
        reset_session
        redirect_to '/login' and return
      end

      User.current = user
    end
  end

end
