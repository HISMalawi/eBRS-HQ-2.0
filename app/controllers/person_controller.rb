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
      @pie_stats[code] += 1
    end
    
  end

  def show
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
