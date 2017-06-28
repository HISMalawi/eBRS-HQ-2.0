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

  def admin?
    ((User.current.user_role.role.role.strip.downcase.match(/Administrator/i) rescue false) ? true : false)
  end

end
