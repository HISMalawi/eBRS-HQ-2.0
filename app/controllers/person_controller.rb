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
      @stats_months << "#{start_date.to_date.month}#{start_date.to_date.year}".to_i #end_date.to_date.month

      (@last_twelve_months_reported_births.keys || []).each do |code|
        details = PersonBirthDetail.where("acknowledgement_of_receipt_date BETWEEN ? AND ? 
          AND LEFT(district_id_number,#{code.length}) = ?", 
          start_date, end_date, code).count
      
        @last_twelve_months_reported_births[code]["#{start_date.to_date.month}#{start_date.to_date.year}".to_i] = details
      end
    end


    available_years = []
    (@stats_months || []).each do |m|
      available_years << m.to_s[-4..-1].to_i
      available_years = available_years.sort.uniq
    end

    @sorted_months_years = []

    (available_years || []).each do |y|
      sorted_x = []
      (@stats_months || []).each do |m|
        next unless m.to_s.match(/#{y}/i)
        sorted_x << m
        sorted_x = sorted_x.sort
      end
     
      (sorted_x || []).each do |s|
        @sorted_months_years << s
      end
    end

=begin
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
=end
    
    @districts_stats  = {}

    (@sorted_months_years || []).each do |period|
      @last_twelve_months_reported_births.sort_by{|x, y|}.each do |code, data|
        @districts_stats[code] = [] if @districts_stats[code].blank?
        (data || {}).sort_by{|x, y| x}.reverse.each do |m, count|
          next unless m.to_i == period.to_i
          @districts_stats[code] << count 
        end
      end

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

    @status = PersonRecordStatus.status(@person.id)
    if ["HQ-POTENTIAL DUPLICATE-TBA","HQ-POTENTIAL DUPLICATE","HQ-DUPLICATE"].include? @status
        redirect_to "/person/duplicate?person_id=#{@person.id}&index=0"
    end

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
    district = Location.find(@birth_details.district_of_birth)

    birth_location = birth_loc.name rescue nil

    @place_of_birth = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

    @place_of_birth = @birth_details.other_birth_location if @place_of_birth.blank?

    @status = PersonRecordStatus.status(@person.id)

    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, [@status])

    @record = {
          "Details of Child" => [
              {
                  "Birth Entry Number" => "#{@birth_details.ben rescue nil}",
                  "Birth Registration Number" => "#{@birth_details.brn  rescue nil}"
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
                  "District" => "#{district.name}",
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
                  "If yes, date of marriage" => "#{@birth_details.date_of_marriage.to_date.strftime('%d/%b/%Y')  rescue nil}"
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
                  "Relationship to child" => "#{@birth_details.informant_relationship_to_child rescue ""}",
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
                  "Phone Number" =>"#{@informant_person.get_attribute('Cell Phone Number') rescue nil}",
                  "Informant Signed?" => "#{(@birth_details.form_signed == 1 ? 'Yes' : 'No')}"
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
        @results = []
        duplicates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision']) 
            
        duplicates.each do |dup|
            next if DuplicateRecord.where(person_id: person['person_id']).present?
            @results << dup if PotentialDuplicate.where(person_id: dup['_id']).blank? 
        end  
        
        if @results.present?
           potential_duplicate = PotentialDuplicate.create(person_id: @person.person_id,created_at: (Time.now))
           if potential_duplicate.present?
                 @results.each do |result|
                    potential_duplicate.create_duplicate(result["_id"])
                 end
           end
           #PersonRecordStatus.new_record_state(@person.person_id, "HQ-POTENTIAL DUPLICATE-TBA", "System mark record as potential duplicate")
           @status = "HQ-POTENTIAL DUPLICATE-TBA" #PersonRecordStatus.status(@person.id)
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

    params[:statuses] = [] if params[:statuses].blank?
    session[:list_url] = request.fullpath
    @states = params[:statuses]
    @section = params[:destination]
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states) rescue []

    if !params[:start].blank?
      length = params[:length].to_i || 10
      start =  params[:start].to_i + 1

      state_ids = @states.collect{|s| Status.find_by_name(s).id} + [-1]
      types=['Normal', 'Abandoned', 'Adopted', 'Orphaned']
      person_reg_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]

      d = Person.order(" cp.created_at ")
      .joins(" INNER JOIN core_person cp ON person.person_id = cp.person_id
              INNER JOIN person_name n ON person.person_id = n.person_id
              INNER JOIN person_record_statuses prs ON person.person_id = prs.person_id AND COALESCE(prs.voided, 0) = 0
              INNER JOIN person_birth_details pbd ON person.person_id = pbd.person_id ")
      .where(" prs.status_id IN (#{state_ids.join(', ')})
              AND pbd.birth_registration_type_id IN (#{person_reg_type_ids.join(', ')}) ")
      data = d.group(" prs.person_id ")

      data = data.select(" n.*, prs.status_id, pbd.district_id_number AS ben, person.gender, person.birthdate, pbd.national_serial_number AS brn ")
      data = data.page(start)
      .per_page(length)

      total = d.select(" count(*) c ")[0]['c'] rescue 0
      @records = []
      data.each do |p|
        mother = PersonService.mother(p.person_id)
        father = PersonService.father(p.person_id)
        details = PersonBirthDetail.find_by_person_id(p.person_id)

        name          = ("#{p['first_name']} #{p['middle_name']} #{p['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
        @records << [
            p.person_id,
            p.ben,
            details.brn,
            p.gender,
            p.birthdate.strftime('%d/%b/%Y'),
            name,
            father_name,
            mother_name,
            Status.find(p.status_id).name,
            p['created_at'].to_date.strftime("%d/%b/%Y")]
      end

      render :text => {
          "draw" => params[:draw].to_i,
          "recordsTotal" => total,
          "recordsFiltered" =>  @records.length,
          "data" => @records}.to_json and return
    end

   # @records = PersonService.query_for_display(@states)

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
              ["Manage Cases","Manage Cases" , [], "/person/manage_cases","/assets/folder3.png"],
              ["Rejected Cases" , "Rejected Cases" , [],"/person/rejected_cases","/assets/folder3.png"],
              ["Edited Records from DC" , "Edited record from DC" , ['HQ-RE-APPROVED'],"/person/view","/assets/folder3.png"],
              ["Special Cases" ,"Special Cases" , [],"/person/special_cases","/assets/folder3.png" ],
              ["Duplicate Cases" , "Duplicate cases" , [],"/person/duplicates_menu","/assets/folder3.png"],
              ["Amendment Cases" , "Amendment Cases" , [],"/person/amendments","/assets/folder3.png"],
              ["Print Out" , "Print outs" , [],"/person/print_out","/assets/folder3.png"],
              ["Reports" , "Reports" , [],"/reports","/assets/reports/chart.png"]
            ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Task(s)"
  end

  def amendments
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Lost/Damaged", "Lost/Damaged", ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
        ["Amendments", "Amendments", ["HQ-PRINTED"], "/person/view","/assets/folder3.png"],
        ["Closed Amended Records", "Closed Amended Records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"]
    ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Manage Cases"

    render :template => "/person/tasks"
  end

  def manage_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
              ["Active Records" ,"Record new arrived from DC", ["HQ-ACTIVE"],"/person/view","/assets/folder3.png", 'Data Checking Clerk'],
              ["Active Records" ,"Record new arrived from DC", ["HQ-ACTIVE"],"/person/view","/assets/folder3.png", 'Data Supervisor'],
              ["Active Records", "View Cases" , ["HQ-COMPLETE"],"/person/view","/assets/folder3.png", 'Data Manager'],
             # ["Conflict Cases", "Conflict Cases" , ["HQ-CONFLICT-TBA"],"/person/view","/assets/folder3.png"],
              ["Incomplete Records from DV","Incomplete records from DV" , ["HQ-INCOMPLETE"],"/person/view","/assets/folder3.png"],
              ["Print Cases", "Printed records", ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
              ["View Printed Records", "Printed records", ["HQ-PRINTED"],"/person/view","/assets/folder3.png"],
              ["Dispatched Records", "Dispatched records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"]
          ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }
    @stats = PersonRecordStatus.stats
    @section = "Manage Cases"

    render :template => "/person/tasks"
  end

  def print_out
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Approve Printing" ,"All records pending Approval to generate Registration Number", ["HQ-COMPLETE"],"/person/view","/assets/folder3.png"],
        ["Print Certificates", "All records pending to be printed " , ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
        ["Re-print Certificates", "Conflict Cases" , ["HQ-CAN-RE-PRINT"],"/person/view","/assets/folder3.png"],
        ["Approve Re-print from QS", "Incomplete records from DV" , ["HQ-RE-PRINT"],"/person/view","/assets/folder3.png"],
        ["Closed Re-printed Certificates","All reprinted records that didn’t pass QC" , ["HQ-PRINTED"],"/person/view","/assets/folder3.png"]
    ]

    @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Print Out"

    render :template => "/person/tasks"
  end

  def rejected_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks =
      [
        ["Approved for Printing" ,"Approved for Printing", ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
        ["Incomplete Cases" ,"Incomplete Cases", ["HQ-INCOMPLETE-TBA"],"/person/view","/assets/folder3.png"],
        ["Rejected records" ,"Rejected records", ["HQ-CAN-REJECT"],"/person/view","/assets/folder3.png"]
      ]
    
    @tasks.reject{|task| !@folders.include?(task[0]) }
    
    @stats = PersonRecordStatus.stats
    @section = "Rejected Cases"

    render :template => "/person/tasks"
  end

  def special_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Abandoned Cases" ,"All records that were registered as Abandoned ", [],"/person/view","/assets/folder3.png"],
        ["Adopted Cases", "All records that were registered as Adopted" , [],"/person/view","/assets/folder3.png"],
        ["Orphaned cases", "All records that were registered as Orphaned" , [],"/person/view","/assets/folder3.png"],
        ["Printed/Dispatched Certificates", "All approved and printed Special cases", [],"/person/view","/assets/folder3.png", 'Quality Supervisor']
    ]

    @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Special Cases"

    render :template => "/person/tasks"
  end

  def get_comments
    @statuses = PersonRecordStatus.where(" person_id = #{params[:person_id]} AND COALESCE(comments, '') != '' ").order('created_at')
  
    @comments = []

    @statuses.each do |audit|
      user = User.find(audit.creator) rescue User.first
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


  def multiple_status_change
    params[:person_ids].split(',').each do |person_id|
      PersonRecordStatus.new_record_state(person_id, params[:status])
    end

    render :text => 'ok'
  end

  def print

    print_errors = {}
    print_error_log = Logger.new(Rails.root.join("log","print_error.log"))
    paper_size = GlobalProperty.find("paper_size").value rescue 'A4'

    if paper_size == "A4"
      zoom = 0.83
    elsif paper_size == "A5"
      zoom = 0.6
    end

    person_ids = params[:person_ids].split(',')
    person_ids.each do |person_id|
      begin
        PersonRecordStatus.new_record_state(person_id, 'HQ-PRINTED', 'Printed Child Record')
        print_url = "wkhtmltopdf --zoom #{zoom} --page-size #{paper_size} #{SETTINGS["protocol"]}://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/birth_certificate?person_ids=#{person_id} #{SETTINGS['certificates_path']}#{person_id}.pdf\n"

        puts print_url
        t4 = Thread.new {
          Kernel.system print_url
          sleep(4)
          Kernel.system "lp -d #{params[:printer_name]} #{SETTINGS['certificates_path']}#{person_id}.pdf\n"
          sleep(5)
        }
        sleep(1)

      rescue => e
        print_errors[person_id] = e.message + ":" + e.backtrace.inspect
      end
    end

    if print_errors.present?
      print_errors.each do |k,v|
        print_error_log.debug "#{k} : #{v}"
      end
    end

    redirect_to session[:list_url]
  end

  def print_preview
    @section = "Print Preview"
    @available_printers = SETTINGS["printer_name"].split('|')
    render :layout => false
  end

  def birth_certificate

    @data = []
    person_ids = params[:person_ids].split(',')
    person_ids.each do |person_id|
      data = {}
      data['person'] = Person.find(person_id)
      data['birth']  = PersonBirthDetail.where(person_id: person_id).last

      barcode = File.read("#{SETTINGS['barcodes_path']}#{data['person'].id}.png") rescue nil
      if barcode.nil?
        p = Process.fork{`bin/generate_barcode #{ data['person'].id} #{ data['person'].id} #{SETTINGS['barcodes_path']}`}
        Process.detach(p)
      end
      sleep(0.5)
      data['barcode'] = File.read("#{SETTINGS['barcodes_path']}#{data['person'].id}.png")

      @data << data
    end

    render :layout => false, :template => 'person/birth_certificate'
  end

  ########################### Duplicates ###############################
  def duplicates_menu
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
   
    @tasks = [
              ["Potential Duplicates","Potential Duplicates" , ["HQ-POTENTIAL DUPLICATE"],"/person/view","/assets/folder3.png"],
              ["Can Confirm Duplicates","Can Confirm Duplicate" , ["HQ-DUPLICATE"],"/person/view","/assets/folder3.png"],
              ["Confirmed Duplicates","Confirmed Duplicate" , ["HQ-VOIDED DUPLICATE"],"/person/view","/assets/folder3.png"],
              ["Resolve Potential Duplicates","Resolve Potential Duplicates" , ["HQ-POTENTIAL DUPLICATE-TBA","HQ-NOT DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Approved for Printing","Approved for printing" , ['HQ-CAN-PRINT'],"/person/view?had=HQ-POTENTIAL DUPLICATE-TBA","/assets/folder3.png"],
              ["Voided Records","Voided Records" , ["HQ-VOIDED DUPLICATE"],"/person/view","/assets/folder3.png"]
            ]
    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }
    @section = "Manage duplicate"
    @stats = PersonRecordStatus.stats
    render :template => "/person/tasks"
  end
  def duplicate
    @section = "Manage Duplicates"
    @operation = "Resolve"
    @potential_duplicate =  person_details(params[:person_id])
    @potential_records = PotentialDuplicate.where(:person_id => (params[:person_id].to_i)).last
    @similar_records = []
    @comments = PersonRecordStatus.where(" person_id = #{params[:person_id]} AND COALESCE(comments, '') != '' ")
    @potential_records.duplicate_records.each do |record|
      @similar_records << person_details(record.person_id)
    end
  end

  def duplicate_processing
    if params[:operation] == "System"
      PersonRecordStatus.new_record_state(params[:id], "HQ-POTENTIAL DUPLICATE",  (params[:comment].present? ? params[:comment] : "System marked record as duplicate" ))
      redirect_to params[:next_url].to_s
    elsif params[:operation] =="Resolve"
         potential_records = PotentialDuplicate.where(:person_id => (params[:id].to_i)).last

         if potential_records.present?
            if params[:decision] == "NOT DUPLICATE"
              PersonRecordStatus.new_record_state(params[:id], 'HQ-CAN-PRINT', params[:comment])
            else
                PersonRecordStatus.new_record_state(params[:id], 'HQ-DUPLICATE', params[:comment])
            end
            potential_records.resolved = 1
            potential_records.decision = params[:decision]
            potential_records.comment = params[:comment]
            potential_records.resolved_at = Time.now
            potential_records.save
        end
        redirect_to "/person/view?statuses[]=HQ-POTENTIAL DUPLICATE-TBA&statuses[]=HQ-NOT DUPLICATE-TBA&destination=Resolve Potential Duplicates"

    elsif params[:operation] == "Confirm-duplicate"

        potential_records = PotentialDuplicate.where(:person_id => (params[:id].to_i)).last
        if potential_records.present?
            if params[:decision] == "NOT DUPLICATE"
                PersonRecordStatus.new_record_state(params[:id], 'HQ-NOT DUPLICATE-TBA', params[:comment])
            else
               PersonRecordStatus.new_record_state(params[:id], 'HQ-POTENTIAL DUPLICATE-TBA', params[:comment])
            end
        end
        redirect_to "/person/view?statuses[]=HQ-POTENTIAL DUPLICATE&destination=Potential Duplicate"

    elsif params[:operation] == "Void-duplicate"

        PersonRecordStatus.new_record_state(params[:id], 'HQ-VOIDED DUPLICATE', params[:comment])
        redirect_to "/person/view?statuses[]=HQ-DUPLICATE&destination=Duplicate Cases"

    elsif params[:operation] == "Verify-DC"

        PersonRecordStatus.new_record_state(params[:id], 'DC-VERIFY DUPLICATE', params[:comment])
        redirect_to "/person/view?statuses[]=HQ-DUPLICATE&destination=Duplicate Cases"

    else

      PersonRecordStatus.new_record_state(params[:id], 'HQ-POTENTIAL DUPLICATE', params[:comment])
      redirect_to "/person/view?statuses[]=HQ-POTENTIAL DUPLICATE-TBA&destination=Potential Duplicate"

    end
  end

  def person_details(id)

    person_mother_id = PersonRelationType.find_by_name("Mother").id
    person_father_id = PersonRelationType.find_by_name("Father").id
    informant_type_id = PersonType.find_by_name("Informant").id

    relations = PersonRelationship.find_by_sql(['select * from person_relationship where person_a = ?', id]).map(&:person_b)
    informant_id = CorePerson.find_by_sql(['select * from core_person
                    where person_type_id = ?
                    and person_id in (?)',informant_type_id, relations]).map(&:person_id)

    #raise @informant.inspect

    person_mother_relation = PersonRelationship.find_by_sql(["select * from person_relationship where person_a = ? and person_relationship_type_id = ?",params[:id], person_mother_id])
    mother_id = person_mother_relation.map{|relation| relation.person_b} #rescue nil
    father_id = PersonRelationship.where(person_a: id,
                                          person_relationship_type_id: person_father_id).first.person_b rescue nil

    person_name = PersonName.find_by_person_id(id)
    person = Person.find(id)
    core_person = CorePerson.find(id)
    birth_details = PersonBirthDetail.find_by_person_id(id)
    person_record_status = PersonRecordStatus.where(:person_id => id).last
    person_status = person_record_status.status.name rescue nil

    actions = ActionMatrix.read_actions(User.current.user_role.role.role, [person_status]) rescue nil

    mother = Person.find(mother_id)
    mother_name = PersonName.find_by_person_id(mother_id)
    father = Person.find(father_id) rescue nil
    father_name = PersonName.find_by_person_id(father_id)
    mother_address = PersonAddress.find_by_person_id(mother_id)
    father_address =  PersonAddress.find_by_person_id(father_id)


    informant = Person.find(informant_id)
    informant_name = PersonName.find_by_person_id(informant_id)

    location_of_birth =""
    place_of_birth = Location.find(birth_details.place_of_birth).name
    case place_of_birth.downcase
    when "hospital"
      location_of_birth = Location.find(birth_details.birth_location_id).name
    when "home"
      village_of_birth = Location.find(birth_details.birth_location_id)
      ta_of_birth  = Location.find(village_of_birth.parent_location)
      district_of_birth = Location.find(ta_of_birth.parent_location)
      location_of_birth = (village_of_birth.name rescue '') +" "+ (ta_of_birth.name rescue '') +" "+
                          (district_of_birth.name rescue '')

    when "other"
      location_of_birth = birth_details.other_birth_location
    end

    person = {
              id: person.id,
              first_name: person_name.first_name,
              last_name: person_name.last_name,
              middle_name: person_name.middle_name,
              birth_entry_number: (birth_details.district_id_number rescue "XXXXXXXXXX"),
              birth_registration_number:( birth_details.national_serial_number rescue "XXXXXXXXXX"),
              birthdate: person.birthdate,
              gender: person.gender,
              status: person_status,
              place_of_birth: (Location.find(birth_details.place_of_birth).name rescue nil),
              location_of_birth: location_of_birth,
              hospital_of_birth: (Location.find(birth_details.birth_location_id).name rescue nil),
              birth_address: (person.birth_address rescue nil),
              village_of_birth: (person.birth_village rescue nil),
              ta_of_birth: (person.birth_ta rescue nil),
              district_of_birth: (person.birth_district rescue nil),
              mother_first_name: (mother_name.first_name rescue nil),
              mother_last_name:(mother_name.last_name rescue nil),
              mother_middle_name: (mother_name.middle_name rescue nil),
              mother_district: (Location.find(mother_address.current_district).name rescue nil),
              mother_village:(Location.find(mother_address.current_village).name rescue nil),
              mother_ta: (Location.find(mother_address.current_ta).name rescue nil),
              father_first_name: (father_name.first_name rescue nil),
              father_last_name: (father_name.last_name rescue nil),
              father_middle_name: (father_name.middle_name rescue nil),
              father_district: (Location.find(father_address.current_district).name rescue nil),
              father_ta: (Location.find(father_address.current_ta).name rescue nil),
              father_village: (Location.find(father_address.current_village).name rescue nil)
    }
    return person
    
  end
  

  def dispatch_certificates

    @people = Person.find_by_sql("SELECT * FROM person WHERE person_id IN (#{params[:person_ids]}) ")
    @people.each do |person|
      PersonRecordStatus.new_record_state(person.id, 'HQ-DISPATCHED')
    end

    path = "#{SETTINGS['certificates_path']}dispatch_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"

    print_url = "wkhtmltopdf 	--orientation landscape --page-size A4 #{SETTINGS["protocol"]}://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/person/dispatch_list?person_ids=#{params[:person_ids]} #{path}.pdf\n"

    puts print_url
    t4 = Thread.new {
      Kernel.system print_url
      sleep(4)
      Kernel.system "lp -d #{params[:printer_name]} #{path}.pdf\n"
      sleep(5)
    }
    sleep(1)

    redirect_to session[:list_url]
  end

  def dispatch_list
    @people = Person.find_by_sql("SELECT n.*, p.gender, p.birthdate, d.national_serial_number, d.district_id_number, d.date_registered FROM person p
                                 INNER JOIN person_birth_details d ON d.person_id = p.person_id
                                 INNER JOIN person_name n ON n.person_id = p.person_id
                        WHERE d.person_id IN (#{params[:person_ids]}) ")
    @district = (Location.find(@people.first.birth_location_id).district rescue nil)
    if @district.blank?
      @district = (Location.find(@people.first.birth_district_id).name rescue nil)
    end

    @data = []
    @people.each do |p|
      details = PersonBirthDetail.where(:person_id => p.person_id).last
      @data << {
          'name'                => p.name,
          'brn'                 => details.brn,
          'ben'                 => details.ben,
          'dob'                 => p.birthdate.to_date.strftime('%d/%b/%Y'),
          'sex'                 => p.gender,
          'date_registered'     => p.date_registered.to_date.strftime('%d/%b/%Y')
      }
    end

    render :layout => false
  end

  def search
  end

  def search_by_identifier
    
    if params[:identifier_type] == 'BRN'
      sql = " WHERE d.national_serial_number LIKE '#{params[:identifier].gsub('-','/')}%'"
    else
      sql = " WHERE d.district_id_number LIKE '#{params[:identifier].gsub('-','/')}%'"
    end

    people = Person.find_by_sql("SELECT n.*, p.gender, p.birthdate, 
      d.national_serial_number, d.district_id_number, 
      d.date_registered FROM person p
      INNER JOIN person_birth_details d ON d.person_id = p.person_id
      INNER JOIN person_name n ON n.person_id = p.person_id
      #{sql} AND n.voided = 0 GROUP BY n.person_id")

    data = []
    (people || []).each do |p|
      data << {
          person_id:           p.person_id,
          first_name:          p.first_name,
          middle_name:         (p.middle_name.blank? == true ? 'N/A' : p.middle_name),
          last_name:           p.last_name,
          brn:                 (p.national_serial_number.blank? == true ? 'N/A' : p.national_serial_number),
          ben:                 p.district_id_number,
          dob:                 (p.birthdate.to_date.strftime('%d/%b/%Y') rescue 'N/A'),
          gender:              p.gender,
          status:              PersonRecordStatus.status(p.person_id),
          date_registered:     p.date_registered.to_date.strftime('%d/%b/%Y')
      }
    end

    render text: data.to_json 
  end

end
