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
        result = Location.where(location_id: id).name rescue nil
      else
        tagmap = LocationTagMap.where(location_tag_id: tag_id, location_id: id).last rescue nil
        if tagmap
          result = Location.find(tagmap.location_id) rescue nil
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
    @mother_name = @father_person.person_names.last rescue nil

    @informant_person = @person.informant rescue nil
    @informant_address = @informant_person.addresses.last rescue nil
    @informant_name = @informant_person.person_names.last rescue nil

    @available_printers = SETTINGS["printer_name"].split('|')

    days_gone = ((@birth_details.acknowledgement_of_receipt_date.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
    delayed =  days_gone > 42 ? "Yes" : "No"
    location = Location.find(SETTINGS['location_id'])
    facility_code = location.code
    birth_loc = Location.find(@birth_details.birth_location_id)
    birth_location = birth_loc.name rescue nil

    if birth_location == 'Other' && @birth_details.other_birth_location.present?
      @birth_details.other_birth_location
    end

      @record = {
          "Details of Child" => [
              {
                  "District ID Number" => "#{@birth_details.district_id_number rescue nil}",
                  "Serial Number" => "#{@birth_details.national_serial_number rescue nil}"
              },
              {
                  ["First Name", "mandatory"] => "#{@name.first_name rescue nil}",
                  "Other Name" => "#{@name.middle_name rescue nil}",
                  ["Surname", "mandatory"] => "#{@name.last_name rescue nil}"
              },
              {
                  ["Date of birth", "mandatory"] => "#{@person.birthdate}",
                  ["Sex", "mandatory"] => "#{(@person.gender == 'F' ? 'Female' : 'Male')}",
                  "Place of birth" => "#{loc(@birth_details.place_of_birth)}"
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
                  "Type of birth" => "#{@birth_details.type.name rescue nil}",
                  "Other birth specified" => "#{@birth_details.other_type_of_birth rescue nil}"
              },
              {
                  "Are the parents married to each other?" => "#{@birth_details.parents_married_to_each_other rescue nil}",
                  "If yes, date of marriage" => "#{@birth_details.date_of_marriage rescue nil}"
              },

              {
                  "Court Order Attached?" => "#{(@birth_details.court_order_attached.to_s == "1" ? 'Yes' : 'No') rescue nil}",
                  "Parents Signed?" => "#{(@birth_details.parents_signed == "1" ? 'Yes' : 'No') rescue nil}",
                  "Record Complete?" => "#{ (record_complete?(@birth_details) == false ? 'No' : 'Yes')}"
              },
              {
                  "Place where birth was recorded" => "#{loc(@birth_details.location_created_at)}",
                  "Record Status" => "#{}",
                  "Child/Person Type" => "#{@child.relationship.titleize}"
              }
          ],
          "Details of Child's Mother" => [
              {
                  ["First Name", "mandatory"] => "#{@child.mother.first_name rescue nil}",
                  "Other Name" => "#{@child.mother.middle_name rescue nil}",
                  ["Maiden Surname", "mandatory"] => "#{@child.mother.last_name rescue nil}"
              },
              {
                  "Date of birth" => "#{@child.mother.birthdate rescue nil}",
                  "Nationality" => "#{@child.mother.citizenship rescue nil}",
                  "ID Number" => "#{@child.mother.id_number rescue nil}"
              },
              {
                  "Physical Residential Address, District" => "#{@child.mother.current_district rescue nil}",
                  "T/A" => "#{@child.mother.current_ta rescue nil}",
                  "Village/Town" => "#{@child.mother.current_village rescue nil}"
              },
              {
                  "Home Address, Village/Town" => "#{@child.mother.home_village rescue nil}",
                  "T/A" => "#{@child.mother.home_ta rescue nil}",
                  "District" => "#{@child.mother.home_district rescue nil}"
              },
              {
                  "Gestation age at birth in weeks" => "#{@child.gestation_at_birth rescue nil}",
                  "Number of prenatal visits" => "#{@child.number_of_prenatal_visits rescue nil}",
                  "Month of pregnancy prenatal care started" => "#{@child.month_prenatal_care_started rescue nil}"
              },
              {
                  "Mode of delivery" => "#{@child.mode_of_delivery rescue nil}",
                  "Number of children born to the mother, including this child" => "#{@child.number_of_children_born_alive_inclusive rescue nil}",
                  "Number of children born to the mother, and still living" => "#{@child.number_of_children_born_still_alive rescue nil}"
              },
              {
                  "Level of education" => "#{@child.level_of_education rescue nil}"
              }
          ],
          "Details of Child's Father" => [
              {
                  parents_married(@child, "First Name") => "#{@child.father.first_name rescue nil}",
                  "Other Name" => "#{@child.father.middle_name rescue nil}",
                  parents_married(@child, "Surname") => "#{@child.father.last_name rescue nil}"
              },
              {
                  "Date of birth" => "#{@child.father.birthdate rescue nil}",
                  "Nationality" => "#{@child.father.citizenship rescue nil}",
                  "ID Number" => "#{@child.father.id_number rescue nil}"
              },
              {
                  "Physical Residential Address, District" => "#{@child.father.current_district rescue nil}",
                  "T/A" => "#{@child.father.current_ta rescue nil}",
                  "Village/Town" => "#{@child.father.current_village rescue nil}"
              },
              {
                  "Home Address, Village/Town" => "#{@child.father.home_village rescue nil}",
                  "T/A" => "#{@child.father.home_ta rescue nil}",
                  "District" => "#{@child.father.home_district rescue nil}"
              }
          ],
          "Details of Child's Informant" => [
              {
                  "First Name" => "#{@child.informant.first_name rescue nil}",
                  "Other Name" => "#{@child.informant.middle_name rescue nil}",
                  "Family Name" => "#{@child.informant.last_name rescue nil}"
              },
              {
                  "Relationship to child" => "#{@child.informant.relationship_to_child rescue ""}",
                  "ID Number" => "#{@child.informant.id_number rescue ""}"
              },
              {
                  "Physical Address, District" => "#{@child.informant.current_district rescue nil}",
                  "T/A" => "#{@child.informant.current_ta rescue nil}",
                  "Village/Town" => "#{@child.informant.current_village rescue nil}"
              },
              {
                  "Postal Address" => "#{@child.informant.addressline1 rescue nil}",
                  "" => "#{@child.informant.addressline2 rescue nil}",
                  "City" => "#{@child.informant.city rescue nil}"
              },
              {
                  "Phone Number" => "#{@child.informant.phone_number rescue ""}",
                  "Informant Signed?" => "#{@child.form_signed rescue ""}"
              },
              {
                  "Acknowledgement Date" => "#{@child.acknowledgement_of_receipt_date.strftime('%d/%B/%Y') rescue ""}",
                  "Date of Registration" => "#{@child.date_registered.to_date.strftime('%d/%B/%Y') rescue ""}",
                  ["Delayed Registration", "sub"] => "#{delayed}"
              }
          ]
      }

    @section = "View Record"

  end

  def view
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
              ["Duplicate Cases" , "Duplicate cases" , [],"/person/duplicates","/assets/folder3.png"],
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
              ["Incomplete records from DV","Incomplete records from DV" , ["HQ-INCOMPLETE"],"/person/view","/assets/folder3.png"],
              ["View printed records","Printed records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"],
              ["Dispatched Records", "Dispatched records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"],

            ]
      @section = "Manage Cases"
      render :template => "/person/tasks"
  end


end
