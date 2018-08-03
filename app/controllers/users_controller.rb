class UsersController < ApplicationController

  #Displays User Management Section
  def index

    @icoFolder = icoFolder("icoFolder")
    #raise @icoFolder.inspect
    @section = "User Management"

    @targeturl = "/"

    @targettext = "Finish"

    render :layout => "facility"
  end

  #Displays The Created User
  def show
    @user = User.find(params[:user_id])
  end

  #Displays All Users
  def view
    @users = User.all.each
    
  end

  #Adds A New User
  def new
    @user = User.new
    @usernames = User.all.map(&:username)
    
    @roles = ['']


    @gender = ['','Female','Male']

  end

  def get_roles
    @roles = [['', '']]
    Role.where(:level => params[:level]).order('role DESC').map do |r|
      @roles << [r.role, r.id]
    end

    render text: @roles.to_json
  end

  # Edits Selected User
  def edit
    @user = User.find(params[:user_id])
    @usernames = User.all.map(&:username)
    
    @roles = ['']
    
    Role.where(:level => 'HQ').map do |r|
      @roles << [r.role, r.id]
    end
    
    @gender = ['','Female','Male']

  end

  #Creates A New User
  def create

    role = Role.find(params[:post][:user_role]['role'])
    username = params[:post][:username]
    password = params[:post][:password]
    email    = params[:post][:email]

    first_name  = params[:post][:person_name][:first_name]
    last_name   = params[:post][:person_name][:last_name]
    similar_users = User.where(username: username)
    if similar_users.count > 0
      raise "User with Username = #{username} Already Exists, Please Try Another Username".to_s
    end

    ActiveRecord::Base.transaction do
      core_person = CorePerson.create(person_type_id: PersonType.where(name: 'User').first.id)
      #person = Person.create(birthdate: '1700-01-01', birthdate_estimated: true, gender: gender, person_id: core_person.id)

      names = PersonName.create(first_name: first_name, last_name: last_name, person_id: core_person.id)
      PersonNameCode.create(first_name_code: first_name.soundex,
        last_name_code: last_name.soundex, person_name_id: names.id)

      user = User.create(person_id: core_person.id, username: username, password_hash: password, location_id:
          SETTINGS['location_id'], email: email, last_password_date: Time.now)

      UserRole.create(user_id: user.id, role_id: role.id)

      if role.role == "Certificate Signatory"
        uploaded_io = params[:post][:signature]
        if uploaded_io.present?
          File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
            file.write(uploaded_io.read)
          end
          signature = uploaded_io.original_filename
          attribute_type = PersonAttributeType.find_by_name("Signature") 
          PersonAttribute.create(person_id: core_person.id, 
                                 person_attribute_type_id: attribute_type.id, 
                                 value: signature)
          gp = GlobalProperty.find_by_property("signatory")
          gp.destroy if gp.present?
          GlobalProperty.create(property: "signatory", 
                                value: username, 
                                uuid: SecureRandom.uuid)
        end
      end  
      
    end

    redirect_to '/users'
  end

  def update
    role = Role.find(params[:post][:user_role]['role'])
    user = User.find(params[:user_id])
    person = Person.find(user.person_id) rescue nil
    person_name = PersonName.where(person_id: user.person_id).last
    name_code = PersonNameCode.where(person_name_id: person_name.id).last
    user_role = user.user_role
    username = params[:post][:username]
    password = params[:post][:password]
    email    = params[:post][:email]

    first_name  = params[:post][:person_name][:first_name]
    last_name   = params[:post][:person_name][:last_name]
    gender      = (params[:post][:person][:gender].split('')[0] rescue params[:post][:person][:gender]) rescue nil
    ActiveRecord::Base.transaction do

      if password.length > 4
        user.update_attributes(
          password_hash: password,
          password_attempt: 0,
          email: email,
          last_password_date: Time.now)
      end

      person.update_attributes(
          gender: gender,
      ) unless person.blank?

      person_name.update_attributes(
          first_name: first_name,
          last_name: last_name
      )

      user_role.update_attributes(
          role_id: role.id
      )

      if role.role == "Certificate Signatory"
        uploaded_io = params[:post][:signature]
        if uploaded_io.present?
          File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
            file.write(uploaded_io.read)
          end
          signature = uploaded_io.original_filename
          attribute_type = PersonAttributeType.find_by_name("Signature") 
          PersonAttribute.create(person_id: person.id, 
                                     person_attribute_type_id: attribute_type.id, 
                                     value: signature)
        end
      end  

      redirect_to '/users'
    end
  end

  #Displays All Users
  def query_users

    results = []

    users = User.all
      users.each do |user|
    	next if user.core_person.blank? || user.core_person.person_name.blank?

    	record = {
          	"username" => "#{user.username}",
          	"name" => "#{user.core_person.person_name.first_name} #{user.core_person.person_name.last_name}",
          	#"role" => "#{user.user_role.role}",
          	"user_id" => "#{user.user_id}",
         	"active" => (user.active rescue false)
      	    	}

      	results << record
    end

    render :text => results.to_json
  end

  #Gives Back Bloked User Access Rights
  def unblock
    user = User.find(params[:user_id]) rescue nil
    if !user.nil?
      if admin?
        user.update_attributes(active: true, un_or_block_reason: nil)
      end
    end

    redirect_to "/users" and return
  end

  #Revokes User Access Rights
  def block_user

    if params['unblock'].present?
      user = User.find(params[:user_id]) rescue nil
      if !user.nil?
        if admin?
          user.update_attributes(active: true,
                                 un_or_block_reason: 'Unkown')
        end
      end
    else
      user = User.find(params[:user_id]) rescue nil
      if !user.nil?
        if admin?
          user.update_attributes(active: false,
            un_or_block_reason: (params[:reason].blank? ? 'Unknown' : params[:reason]))
        end
      end
    end

    render :text => true
  end

  #Gives Back Bloked User Access Rights
  def void_user
    user = User.find(params[:user_id]) rescue nil

    if !user.blank?
      if admin?
        user.update_attributes(blocked: true)
      end
    end

  render :text => true
  end

  def search

    #redirect_to "/" and return if !(User.current_user.activities_by_level("Facility").include?("View Users"))
    @section = "Search for User"

    @targeturl = "/users"


  end

  def search_by_username

    #redirect_to "/" and return if !(User.current_user.activities_by_level("Facility").include?("View Users"))

    name = params[:id].strip rescue ""

    results = []

    if name.length > 1

      users = User.by_username.key(name).limit(10).each

    else

      users = User.by_username.limit(10).each

    end

    users.each do |user|

      next if user.username.strip.downcase == User.current.username.strip.downcase

      record = {
          "username" => "#{user.username}",
          "fname" => "#{user.core_person.person_name.first_name}",
          "lname" => "#{user.core_person.person_name.last_name}",
          "role" => "#{user.user_role.role}",
          "active" => (user.active rescue false)
      }

      results << record

    end

    render :text => results.to_json

  end

  def search_by_active

    #redirect_to "/" and return if !(User.current_user.activities_by_level("Facility").include?("View Users"))

    status = params[:status] == "true" ? true : false

    results = []

    users = User.by_active.key(status).limit(10).each

    users.each do |user|

      next if user.username.strip.downcase == User.current.username.strip.downcase

      record = {
          "username" => "#{user.username}",
          "fname" => "#{user.core_person.person_name.first_name}",
          "lname" => "#{user.core_person.person_name.last_name}",
          "role" => "#{user.user_role.role}",
          "active" => (user.active rescue false)
      }

      results << record

    end

    render :text => results.to_json

  end



  def username_availability
    user = User.where(username: params[:search_str])
    render :text => user = user.blank? ? 'OK' : 'N/A' and return
  end

  def my_account
    #redirect_to "/" and return if !(User.current_user.activities_by_level("Facility").include?("Change own password"))

    @section = "My Account"

    @targeturl = "/"

    @user = User.current

    render :layout => "facility"

  end

  def change_password
    #redirect_to "/" and return if !(User.current_user.activities_by_level("Facility").include?("Change own password"))

    @section = "Change Password"

    @targeturl = "/"

    @user = User.current

  end

  def update_password

    user = User.find(params[:user_id])

    result = user.password_matches?(params[:old_password])

    if user && !user.password_matches?(params[:old_password])
    	 result = "not same"
    elsif user && user.password_matches?(params[:new_password])
    	 result = "same"
    else
      user.update_attributes(:password_hash => params[:new_password], :password_attempt => 0, :last_password_date => Time.now)
      flash["notice"] = "Your new password has been changed succesfully"

    end

    render :text => result

  end

  def deleted
    @users = User.unscoped.where(voided: true)
  end

  def recover
    user = User.unscoped.find(params[:user_id]) rescue nil
    if !user.nil?
      if admin?
        user.update_attributes(voided: false, void_reason: nil)
      end
    end

    redirect_to "/deleted_users" and return
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:username, :active, :create_at, :creator, :email, :first_name, :last_name, :notify, :plain_password, :role, :updated_at, :_rev)
  end

  def check_if_user_admin
    @search = icoFolder("search")
    @admin = ((User.current.user_role.role.role.strip.downcase.match(/Administrator/i) rescue false) ? true : false)
  end


end
