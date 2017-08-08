class PersonController < ApplicationController
  def index

    @last_twelve_months_reported_births = {}
    last_year = Date.today.ago(11.month).beginning_of_month.strftime('%Y-%m-%d 00:00:00')
    curr_year = Date.today.strftime('%Y-%m-%d 23:59:59') 
    
    location_tag = LocationTag.where(name: 'District').first

    locations = Location.group("location.location_id").where("parent_location IS NULL AND t.location_tag_id = ?",
      location_tag.id).joins("INNER JOIN location_tag_map m 
      ON m.location_id = location.location_id
      INNER JOIN location_tag t 
      ON t.location_tag_id = m.location_tag_id").order("location.location_id ASC")

    (locations || []).each_with_index do |l, i|
      district_code = l.code
      if @last_twelve_months_reported_births[district_code].blank?
        @last_twelve_months_reported_births[district_code] = {} 
      end
    end

    @stats_months = []

    (0.upto(11)).each_with_index do |num, i|
      start_date  = Date.today.ago(num.month).beginning_of_month.strftime('%Y-%m-%d 00:00:00')
      end_date    = start_date.to_date.end_of_month.strftime('%Y-%m-%d 23:59:59')
      @stats_months << end_date.to_date.month

      (@last_twelve_months_reported_births.keys || []).each do |code|
        details = PersonBirthDetail.where("created_at BETWEEN ? AND ? 
          AND LEFT(district_id_number,#{code.length}) = ?", 
          start_date, end_date, code).count
      
        @last_twelve_months_reported_births[code][start_date.to_date.month] = details
      end
    end

    @districts_stats  = {}
    #raise @stats_months.sort.reverse.inspect

    @last_twelve_months_reported_births.sort_by{|x, y|}.each do |code, data|
      @districts_stats[code] = []
      (data || {}).sort_by{|x, y| x}.reverse.each do |m, count|
        @districts_stats[code] << count
      end
    end

    ############################################
    @pie_stats = {}
    
    (locations || []).each_with_index do |l, i|
      @pie_stats[l.code] = 0 
    end

    details = PersonBirthDetail.where("district_id_number IS NOT NULL")
    (details || []).each do |d|
      code = d.district_id_number.split('/')[0]
      @pie_stats[code] = 0 if @pie_stats[code].blank?
      @pie_stats[code] += 1
    end

    @stats = PersonRecordStatus.stats
    @section = "National Statistics Summary"
  end

  def loc(id, tag=nil)
      tag_id = LocationTag.where(name: tag).last.id rescue nil
      result = nil
      if tag_id.blank?
        result = Location.find(id).name rescue nil
      else
        tagmap = LocationTagMap.where(location_tag_id: tag_id, location_id: id).last rescue nil
        if tagmap
          result = Location.find(tagmap.location_id).name rescue nil
        end
      end

    result
  end

  def show
    @core_person = CorePerson.find(params[:person_id])
    @person = @core_person.person

    @birth_details = PersonBirthDetail.where(person_id: @core_person.person_id).last
    @name = @person.person_names.last
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_address = @mother_person.addresses.last rescue nil
    @mother_name = @mother_person.person_names.last rescue nil

    @father_person = @person.father
    @father_address = @father_person.addresses.last rescue nil
    @father_name = @father_person.person_names.last rescue nil

    @informant_person = @person.informant rescue nil
    @informant_address = @informant_person.addresses.last rescue nil
    @informant_name = @informant_person.person_names.last rescue nil

    @available_printers = SETTINGS["printer_name"].split('|')
    @comments = PersonRecordStatus.where(" person_id = #{@person.id} AND COALESCE(comments, '') != '' ")
    days_gone = ((@birth_details.acknowledgement_of_receipt_date.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
    @delayed =  days_gone > 42 ? "Yes" : "No"
    location = Location.find(SETTINGS['location_id'])
    facility_code = location.code
    birth_loc = Location.find(@birth_details.birth_location_id)
    
    birth_location = birth_loc.name rescue nil

    @place_of_birth = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

    @place_of_birth = @birth_details.other_birth_location if @place_of_birth.blank?

    @status = PersonRecordStatus.status(@person.id)
    @record = {
          "Details of Child" => [
              {
                  "District ID Number" => "#{@birth_details.district_id_number rescue nil}",
                  "Serial Number" => "#{@birth_details.national_serial_number  rescue nil}"
              },
              {
                  ["First Name", "mandatory"] => "#{@name.first_name rescue nil}",
                  "Other Name" => "#{@name.middle_name rescue nil}",
                  ["Surname", "mandatory"] => "#{@name.last_name rescue nil}"
              },
              {
                  ["Date of birth", "mandatory"] => "#{@person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                  ["Sex", "mandatory"] => "#{(@person.gender == 'F' ? 'Female' : 'Male')}",
                  "Place of birth" => "#{loc(@birth_details.place_of_birth, 'Place of Birth')}"
              },
              {
                  "Name of Hospital" => "#{loc(@birth_details.birth_location_id, 'Health Facility')}",
                  "Other Details" => "#{@birth_details.other_birth_location}",
                  "Address" => "#{@child.birth_address rescue nil}"
              },
              {
                  "District" => "#{birth_loc.district}",
                  "T/A" => "#{birth_loc.ta}",
                  "Village" => "#{birth_loc.village rescue nil}"
              },
              {
                  "Birth weight (kg)" => "#{@birth_details.birth_weight rescue nil}",
                  "Type of birth" => "#{@birth_details.birth_type.name rescue nil}",
                  "Other birth specified" => "#{@birth_details.other_type_of_birth rescue nil}"
              },
              {
                  "Are the parents married to each other?" => "#{(@birth_details.parents_married_to_each_other.to_s == '1' ? 'Yes' : 'No') rescue nil}",
                  "If yes, date of marriage" => "#{@birth_details.date_of_marriage rescue nil}"
              },

              {
                  "Court Order Attached?" => "#{(@birth_details.court_order_attached.to_s == "1" ? 'Yes' : 'No') rescue nil}",
                  "Parents Signed?" => "#{(@birth_details.parents_signed == "1" ? 'Yes' : 'No') rescue nil}",
                  "Record Complete?" => "----"
              },
              {
                  "Place where birth was recorded" => "#{loc(@birth_details.location_created_at)}",
                  "Record Status" => "#{@status}",
                  "Child/Person Type" => "#{@birth_details.reg_type.name}"
              }
          ],
          "Details of Child's Mother" => [
              {
                  ["First Name", "mandatory"] => "#{@mother_name.first_name rescue nil}",
                  "Other Name" => "#{@mother_name.middle_name rescue nil}",
                  ["Maiden Surname", "mandatory"] => "#{@mother_name.last_name rescue nil}"
              },
              {
                  "Date of birth" => "#{@mother_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                  "Nationality" => "#{@mother_person.citizenship rescue nil}",
                  "ID Number" => "#{@mother_person.id_number rescue nil}"
              },
              {
                  "Physical Residential Address, District" => "#{loc(@mother_address.current_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@mother_address.current_ta, 'Traditional Authority') rescue nil}",
                  "Village/Town" => "#{loc(@mother_address.current_village, 'Village') rescue nil}"
              },
              {
                  "Home Address, Village/Town" => "#{loc(@mother_address.home_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@mother_address.home_ta, 'Traditional Authority') rescue nil}",
                  "District" => "#{loc(@mother_address.home_village, 'Village') rescue nil}"
              },
              {
                  "Gestation age at birth in weeks" => "#{@birth_details.gestation_at_birth rescue nil}",
                  "Number of prenatal visits" => "#{@birth_details.number_of_prenatal_visits rescue nil}",
                  "Month of pregnancy prenatal care started" => "#{@birth_details.month_prenatal_care_started rescue nil}"
              },
              {
                  "Mode of delivery" => "#{@birth_details.mode_of_delivery.name rescue nil}",
                  "Number of children born to the mother, including this child" => "#{@birth_details.number_of_children_born_alive_inclusive rescue nil}",
                  "Number of children born to the mother, and still living" => "#{@birth_details.number_of_children_born_still_alive rescue nil}"
              },
              {
                  "Level of education" => "#{@birth_details.level_of_education rescue nil}"
              }
          ],
          "Details of Child's Father" => [
              {
                  "First Name" => "#{@father_name.first_name rescue nil}",
                  "Other Name" => "#{@father_name.middle_name rescue nil}",
                  "Surname" => "#{@father_name.last_name rescue nil}"
              },
              {
                  "Date of birth" => "#{@father_person.birthdate.to_date.strftime('%d/%b/%Y') rescue nil}",
                  "Nationality" => "#{@father_person.citizenship rescue nil}",
                  "ID Number" => "#{@father_person.id_number rescue nil}"
              },
              {
                  "Physical Residential Address, District" => "#{loc(@father_address.current_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@father_address.current_ta, 'Traditional Authority') rescue nil}",
                  "Village/Town" => "#{loc(@father_address.current_village, 'Village') rescue nil}"
              },
              {
                  "Home Address, Village/Town" => "#{loc(@father_address.home_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@father_address.home_ta, 'Traditional Authority') rescue nil}",
                  "District" => "#{loc(@father_address.home_village, 'Village') rescue nil}"
              }
          ],
          "Details of Child's Informant" => [
              {
                  "First Name" => "#{@informant_name.first_name rescue nil}",
                  "Other Name" => "#{@informant_name.middle_name rescue nil}",
                  "Family Name" => "#{@informant_name.last_name rescue nil}"
              },
              {
                  "Relationship to child" => "#{@child.informant.relationship_to_child rescue ""}",
                  "ID Number" => "#{@informant_person.id_number rescue ""}"
              },
              {
                  "Physical Address, District" => "#{loc(@informant_address.home_district, 'District')rescue nil}",
                  "T/A" => "#{loc(@informant_address.current_ta, 'Traditional Authority') rescue nil}",
                  "Village/Town" => "#{loc(@informant_address.current_village, 'Village') rescue nil}"
              },
              {
                  "Postal Address" => "#{@informant_address.addressline1 rescue nil}",
                  "" => "#{@informant_address.addressline2 rescue nil}",
                  "City" => "#{@informant_address.city rescue nil}"
              },
              {
                  "Phone Number" => "#{@informant_person.phone_number rescue ""}",
                  "Informant Signed?" => "#{@birth_details.form_signed rescue ""}"
              },
              {
                  "Acknowledgement Date" => "#{@birth_details.acknowledgement_of_receipt_date.to_date.strftime('%d/%b/%Y') rescue ""}",
                  "Date of Registration" => "#{@birth_details.date_registered.to_date.strftime('%d/%b/%Y') rescue ""}",
                  ["Delayed Registration", "sub"] => "#{@delayed}"
              }
          ]
      }
    if @person.present? && SETTINGS['potential_search']
      person = {}
      person["id"] = @person.person_id.to_s
      person["first_name"]= @name.first_name rescue ''
      person["last_name"] =  @name.last_name rescue ''
      person["middle_name"] = @name.middle_name rescue ''
      person["gender"] = (@person.gender == 'F' ? 'Female' : 'Male')
      person["birthdate"]= @person.birthdate.to_date
      person["birthdate_estimated"] = @person.birthdate_estimated
      person["nationality"]=  @mother_person.citizenship
      person["place_of_birth"] = @place_of_birth
      if  birth_loc.district.present?
        person["district"] = birth_loc.district
      else
        person["district"] = "Lilongwe"
      end      
      person["mother_first_name"]= @mother_name.first_name rescue ''
      person["mother_last_name"] =  @mother_name.last_name  rescue ''
      person["mother_middle_name"] = @mother_name.middle_name rescue '' 
      person["father_first_name"]= @father_name.first_name  rescue ''
      person["father_last_name"] =  @father_name.last_name  rescue ''
      person["father_middle_name"] = @father_name.middle_name  rescue ''
    
      SimpleElasticSearch.add(person)

      if @status == "HQ-ACTIVE"
        @results = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])        
        if @results.present?
           potential_duplicate = PotentialDuplicate.create(person_id: @person.person_id,created_at: (Time.now))
           if potential_duplicate.present?
                 @results.each do |result|
                    potential_duplicate.create_duplicate(result["_id"])
                 end
           end
           PersonRecordStatus.new_record_state(@person.person_id, "HQ-POTENTIAL DUPLICATE-TBA", "System mark record as potential duplicate")
           @status = PersonRecordStatus.status(@person.id)
        end      
      end
    else

    end

    @section = "View Record"

  end

  def parents_married(child, value)
    if child.parents_married_to_each_other.to_s == '1'
      [value, "mandatory"]
    else
      return value
    end
  end

  def view
    session[:list_url] = request.fullpath
    @states = params[:statuses]
    @section = params[:destination]
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states)

    @records = PersonService.query_for_display(@states)
    render :template => "/person/records"
  end


  def records
    person_type = PersonType.where(name: 'Client').first
    @records = Person.where("p.person_type_id = ?", 
      person_type.id).joins("INNER JOIN core_person p ON person.person_id = p.person_id
      INNER JOIN person_name n 
      ON n.person_id = p.person_id").group('n.person_id').select("person.*, n.*").order('p.created_at DESC')
      
         
    render :layout => 'data_table'
  end

  def new
     @person = PersonName.new

     @section = "New Person"
     render :layout => "touch"
  end

  def create
    PersonService.create_record(params)
    redirect_to '/'
  end

  #########################################################################
  
  def get_names
    entry = params["search"].soundex
    if params["last_name"]
      data = PersonName.where("last_name LIKE (?)", "#{params[:search]}%")
      if data.present?
        render text: data.collect(&:last_name).uniq.join("\n") and return
      else
        render text: "" and return
      end
    elsif params["first_name"]
      data = PersonName.where("first_name LIKE (?)", "#{params[:search]}%")
      if data.present?
        render text: data.collect(&:first_name).uniq.join("\n") and return
      else
        render text: "" and return
      end
    end

    render text: ''
  end

  def get_nationality
    nationality_tag = LocationTag.where(name: 'Country').first
    data = ['Malawian']
    Location.where("LENGTH(country) > 0 AND country != 'Malawian' AND country LIKE (?) AND m.location_tag_id = ?", 
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('country ASC').map do |l|
      data << l.country
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  def get_country
    nationality_tag = LocationTag.where(name: 'Country').first
    data = ['Malawi']
    Location.where("LENGTH(name) > 0 AND country != 'Malawi' AND name LIKE (?) AND m.location_tag_id = ?", 
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  def get_district
    nationality_tag = LocationTag.where(name: 'District').first
    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?", 
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  def get_ta
    district_name = params[:district]
    nationality_tag = LocationTag.where(name: 'Traditional Authority').first
    location_id_for_district = Location.where(name: district_name).first.id

    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ? AND parent_location = ?", 
      "#{params[:search]}%", nationality_tag.id, location_id_for_district).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  def get_village
    district_name = params[:district]
    location_id_for_district = Location.where(name: district_name).first.id

    ta_name = params[:ta]
    location_id_for_ta = Location.where("name = ? AND parent_location = ?", 
      ta_name, location_id_for_district).first.id


    nationality_tag = LocationTag.where(name: 'Village').first
    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?
      AND parent_location = ?", "#{params[:search]}%", nationality_tag.id,
      location_id_for_ta).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  def get_hospital
    
    nationality_tag = LocationTag.where(name: 'Health facility').first
    data = []
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?", 
      "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << l.name
    end
    
    if data.present?
      render text: data.compact.uniq.join("\n") and return
    else
      render text: "" and return
    end
  end

  #########################################################################
  def tasks
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
              ["Manage Cases","Manage Cases" , [],"/person/manage_cases","/assets/folder3.png"],
              ["Rejected Cases" , "Rejected Cases" , [],"/person/rejected_cases","/assets/folder3.png"],
              ["Edited record from DC" , "Edited record from DC" , [],"/person/edited_fron_dc","/assets/folder3.png"],
              ["Special Cases" ,"Special Cases" , [],"/person/special_cases","/assets/folder3.png" ],
              ["Duplicate Cases" , "Duplicate cases" , [],"/person/duplicates_menu","/assets/folder3.png"],
              ["Amendment Cases" , "Amendment Cases" , [],"/person/amendments","/assets/folder3.png"],
              ["Print Out" , "Print outs" , [],"/person/print_outs","/assets/folder3.png"],
              ["Birth Reports" , "Reports" , [],"/reports","/assets/reports/chart.png"]
            ]
    @section = "Task(s)"
  end

  def manage_cases
     @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
     @tasks = [
              ["Active Records" ,"Record new arrived from DC", ["HQ-ACTIVE"],"/person/view","/assets/folder3.png"],
              ["View Cases", "View Cases" , ["HQ-COMPLETE"],"/person/view","/assets/folder3.png"],
              ["Conflict Cases", "Conflict Cases" , ["HQ-COMPLETE"],"/person/view","/assets/folder3.png"],
              ["Incomplete Records from DV","Incomplete records from DV" , ["HQ-INCOMPLETE"],"/person/view","/assets/folder3.png"],
              ["View printed records","Printed records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"],
              ["Dispatched Records", "Dispatched records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"],

            ]
      @section = "Manage Cases"
      render :template => "/person/tasks"
  end

  def get_comments
    @statuses = PersonRecordStatus.where(" person_id = #{params[:person_id]} AND COALESCE(comments, '') != '' ").order('created_at')
    @comments = []

    @statuses.each do |audit|
      user = User.find(audit.creator)
      name = PersonName.where(person_id: user.person_id).last
      user_name = (name.first_name + " " + name.last_name)
      ago = ""
      if (audit.created_at.to_date == Date.today)
        ago = "today"
      else
        ago = (Date.today - audit.created_at.to_date).to_i
        ago = ago.to_s + (ago.to_i == 1 ? " day ago" : " days ago")
      end
      @comments << {
          "created_at" => audit.created_at.to_time,
          'user' => user_name,
          'user_role' => (user.user_role.role.role rescue nil),
          'level' => (user.user_role.role.level rescue nil),
          'status' => (Status.find(audit.status_id).name),
          'comment' => audit.comments,
          'date_added' => ago
      }
      @comments = @comments.sort_by{|c| c['created_at']}
    end

    render :text => @comments.to_json
  end

  def ajax_status_change

    PersonRecordStatus.new_record_state(params[:person_id], params[:status], params[:comment])

    render :text => 'ok'
  end

  ########################### Duplicates ###############################
  def duplicates_menu
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
              ["Potential Duplicate","Potential Duplicate" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Can Confirm Duplicate","Can Confirm Duplicate" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Confirmed Duplicate","Confirmed Duplicate" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Resolve potential Duplicates","Resolve potential Duplicates" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Approved for printing","Approved for printing" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Voided Records","Voided Records" , ["HQ-POTENTIAL DUPLICATE-TBA"],"/person/view","/assets/folder3.png"]
            ]
    @section = "Manage duplicate"
    render :template => "/person/tasks"
  end

end
