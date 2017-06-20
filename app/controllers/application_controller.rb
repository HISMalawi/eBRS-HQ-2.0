class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #protect_from_forgery with: :exception
  #protect_from_forgery	#with: :null_session

  before_filter :check_if_logged_in, :except => ['login']

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

  def application_mode
    if SETTINGS['application_mode'] == 'FC'
      return 'Facility'
    else
      return 'DC'
    end
  end

  def login!(user)
    session[:user_id] = user.id 
  end

  def logout!
    session[:user_id] = nil
  end

  private

  def check_if_logged_in
    if session[:user_id].blank?
      if request.filtered_parameters["action"] == 'create' and request.filtered_parameters["controller"] == 'logins'
        return
      end
      
      redirect_to '/login' and return
    else
      User.current = User.find(session[:user_id])
    end
  end

end
