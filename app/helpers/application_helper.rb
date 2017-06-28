module ApplicationHelper
  
  def application_mode
    if SETTINGS['application_mode'] == 'FC'
      return 'Facility'
    else
      return 'DC'
    end
  end

  def preferred_keyboard
    return User.current.preferred_keyboard
  end

  def datatable
    return true
  end

  def application_couchdb
    con = YAML.load_file(File.join(Rails.root, "config", "couchdb.yml"))[Rails.env]
    return "#{con['prefix']}_#{con['suffix']}"
  end

end
