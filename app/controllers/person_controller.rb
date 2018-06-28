class PersonController < ApplicationController
  def index
    if User.current.user_role.role.role == "Quality Supervisor"
      #redirect_to "/person/certificate_verification"
    end

    json = JSON.parse(File.read("#{Rails.root}/dashboard_data.json"))
    @last_twelve_months_reported_births = json["last_twelve_months_reported_births"]
    @stats_months = json["stats_months"]

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
    if  ["HQ-POTENTIAL DUPLICATE-TBA","HQ-NOT DUPLICATE-TBA","HQ-POTENTIAL DUPLICATE","HQ-DUPLICATE"].include? @status
        redirect_to "/person/duplicate?person_id=#{@person.id}&index=0"
    elsif ['HQ-AMEND','HQ-AMEND-GRANTED','HQ-AMEND-REJECTED'].include? @status
        redirect_to "/person/ammend_case?id=#{@person.id}"
    end

    session[:list_url] = request.referrer

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
    days_gone = ((@birth_details.date_registered.to_date rescue Date.today) - @person.birthdate.to_date).to_i rescue 0
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
                  "Birth Registration Number" => "#{@birth_details.brn  rescue nil}",
                  "ID Number" => "#{@person.id_number  rescue nil}"
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
                  "Record Complete?" => (@birth_details.record_complete? rescue false) ? "Yes" : "No"
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
                  "Home Address, District" => "#{loc(@mother_address.home_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@mother_address.home_ta, 'Traditional Authority') rescue nil}",
                  "Village/Town" => "#{loc(@mother_address.home_village, 'Village') rescue nil}"
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
                  "Home Address, DIstrict" => "#{loc(@father_address.home_district, 'District') rescue nil}",
                  "T/A" => "#{loc(@father_address.home_ta, 'Traditional Authority') rescue nil}",
                  "Village/Town" => "#{loc(@father_address.home_village, 'Village') rescue nil}"
              }
          ],
          "Details of Child's Informant" => [
              {
                  "First Name" => "#{@informant_name.first_name rescue nil}",
                  "Other Name" => "#{@informant_name.middle_name rescue nil}",
                  "Family Name" => "#{@informant_name.last_name rescue nil}"
              },
              {
                  "Relationship to child" => "#{@birth_details.informant_relationship_to_person rescue ""}",
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
                  "Date of Reporting" => "#{@birth_details.acknowledgement_of_receipt_date.to_date.strftime('%d/%b/%Y') rescue ""}",
                  "Date Registered" => "#{@birth_details.date_registered.to_date.strftime('%d/%b/%Y') rescue ""}",
                  ["Delayed Registration", "sub"] => "#{@delayed}"
              }
          ]
      }


    @trace_data = PersonRecordStatus.trace_data(@person.id)

    @nid_data = {}
    nid_data = ActiveRecord::Base.connection.select_one <<EOF
          SELECT * FROM nid_verification_data WHERE person_id = #{@person.person_id} ORDER BY id DESC;
EOF

    @nid_data = JSON.parse(nid_data["data"]) if !nid_data.blank?

    if @person.present? && SETTINGS['potential_search']
      person = {}
      person["id"] = @person.person_id.to_s
      person["first_name"]= @name.first_name rescue ''
      person["last_name"] =  @name.last_name rescue ''
      person["middle_name"] = @name.middle_name rescue ''
      person["gender"] = (@person.gender == 'F' ? 'Female' : 'Male')
      person["birthdate"]= @person.birthdate.to_date
      person["birthdate_estimated"] = @person.birthdate_estimated
      person["nationality"]=  @mother_person.citizenship rescue ''
      person["place_of_birth"] = @place_of_birth
      if  birth_loc.district.present?
        person["district"] = birth_loc.district
      else
        person["district"] = "Lilongwe"
      end
      person["mother_first_name"]= @mother_name.first_name rescue ''
      person["mother_last_name"] =  @mother_name.last_name  rescue ''
      person["mother_middle_name"] = @mother_name.middle_name rescue ''

      person["mother_home_district"] = Location.find(@mother_person.addresses.last.home_district).name rescue nil
      person["mother_home_ta"] = Location.find(@mother_person.addresses.last.home_ta).name rescue nil
      person["mother_home_village"] = Location.find(@mother_person.addresses.last.home_village).name rescue nil

      person["mother_current_district"] = Location.find(@mother_person.addresses.last.current_district).name rescue nil
      person["mother_current_ta"] = Location.find(@mother_person.addresses.last.current_ta).name rescue nil
      person["mother_current_village"] = Location.find(@mother_person.addresses.last.current_village).name rescue nil

      person["father_first_name"]= @father_name.first_name  rescue ''
      person["father_last_name"] =  @father_name.last_name  rescue ''
      person["father_middle_name"] = @father_name.middle_name  rescue ''

      person["father_home_district"] = Location.find(@father_person.addresses.last.home_district).name rescue nil
      person["father_home_ta"] = Location.find(@father_person.addresses.last.home_ta).name rescue nil
      person["father_home_village"] = Location.find(@father_person.addresses.last.home_village).name rescue nil

      person["father_current_district"] = Location.find(@father_person.addresses.last.current_district).name rescue nil
      person["father_current_ta"] = Location.find(@father_person.addresses.last.current_ta).name rescue nil
      person["father_current_village"] = Location.find(@father_person.addresses.last.current_village).name rescue nil


      SimpleElasticSearch.add(person)

      if @status == "HQ-ACTIVE"
        @results = []
        duplicates = SimpleElasticSearch.query_duplicate_coded(person,SETTINGS['duplicate_precision'])
        duplicates.each do |dup|
            next if DuplicateRecord.where(person_id: person['id']).present?
            @results << dup if PotentialDuplicate.where(person_id: dup['_id']).blank?
        end

        if @results.present? && !@birth_details.birth_type.name.to_s.downcase.include?("twin")
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

    if !params[:viewport].blank?
      render :layout => "viewport" and return
    end
  end

  def parents_married(child, value)
    if child.parents_married_to_each_other.to_s == '1'
      [value, "mandatory"]
    else
      return value
    end
  end

  def view

    @type_stats = PersonRecordStatus.type_stats(params[:statuses], params[:had], params[:had_by])
    params[:statuses] = [] if params[:statuses].blank?
    session[:list_url] = request.referrer
    @states = params[:statuses]
    @states = Status.all.map(&:name).reject{|n| n.match(/DC\-|FC\-/)} if @states.blank?

    @section = params[:destination]
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, @states) rescue []
    types = []

    @birth_type = params[:birth_type]

    search_val = params[:search][:value] rescue nil
    search_val = '_' if search_val.blank?
    search_category = ''


    if !params[:category].blank?

      if params[:category] == 'continuous'
        search_category = " AND (pbd.source_id IS NULL OR LENGTH(pbd.source_id) >  19)  "
      elsif params[:category] == 'mass_data'
        search_category = " AND (pbd.source_id IS NOT NULL AND LENGTH(pbd.source_id) <  20 ) "
      else
        search_category = ""
      end

      session[:category] = params[:category]
    end

    if !params[:start].blank?

      loc_query = " "
      locations = []

      if params[:district] == "All"
        session[:district] = ""
      end

      if params[:district].present? && params[:district] != "All"
        session[:district] = params[:district]

        locations = [params[:district]]

        facility_tag_id = LocationTag.where(name: 'Health Facility').first.id rescue [-1]
        (Location.find_by_sql("SELECT l.location_id FROM location l
                            INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id = #{facility_tag_id}
                          WHERE l.parent_location = #{params[:district]}") || []).each {|l|
          locations << l.location_id
        }
        loc_query = " AND pbd.location_created_at IN (#{locations.join(', ')}) "
      end

      state_ids = @states.collect{|s| Status.find_by_name(s).id} + [-1]
      types=['Normal', 'Abandoned', 'Adopted', 'Orphaned'] if params[:type] == 'All'
      types=['Abandoned', 'Adopted', 'Orphaned'] if params[:type] == 'All Special Cases'
      types=[params[:type]] if types.blank?

      person_reg_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]

      had_query = ' '
      if !params['had'].blank?
        #probe user who made previous change
        user_hook = ""
        if params['had_by'].present?

          had_by_users =  UserRole.where(role_id: Role.where(role: params['had_by']).last.id).map(&:user_id) rescue [-1]
          had_by_users =  [-1] if had_by_users.blank?
          user_hook = " AND prev_s.creator IN (#{had_by_users.join(', ')}) " if had_by_users.length > 0
        end

        prev_states = params['had'].split('|')
        prev_state_ids = prev_states.collect{|sn| Status.where(name: sn).last.id  rescue -1 }
        had_query = " INNER JOIN person_record_statuses prev_s ON prev_s.person_id = prs.person_id #{user_hook}
             AND prev_s.status_id IN (#{prev_state_ids.join(', ')})"
      end

      d = Person.order(" pbd.district_id_number, pbd.national_serial_number, n.first_name, n.last_name, cp.created_at ")
      .joins(" INNER JOIN core_person cp ON person.person_id = cp.person_id
              INNER JOIN person_name n ON person.person_id = n.person_id
              INNER JOIN person_record_statuses prs ON person.person_id = prs.person_id AND COALESCE(prs.voided, 0) = 0
              #{had_query}
              INNER JOIN person_birth_details pbd ON person.person_id = pbd.person_id ")
      .where(" prs.status_id IN (#{state_ids.join(', ')}) AND n.voided = 0
              AND pbd.birth_registration_type_id IN (#{person_reg_type_ids.join(', ')}) #{loc_query}
              AND concat_ws('_', pbd.national_serial_number, pbd.district_id_number, n.first_name, n.last_name, n.middle_name,
              person.birthdate, person.gender) REGEXP '#{search_val}'  #{search_category} ")

      total = d.select(" count(*) c ")[0]['c'] rescue 0
      page = (params[:start].to_i / params[:length].to_i) + 1

      data = d.group(" prs.person_id ")

      data = data.select(" n.*, prs.status_id, pbd.district_id_number AS ben, person.gender, person.birthdate, pbd.national_serial_number AS brn")
      data = data.page(page)
      .per_page(params[:length].to_i)

      @records = []
      nid_data = []
      data.each do |p|
        mother = PersonService.mother(p.person_id)
        father = PersonService.father(p.person_id)
        details = PersonBirthDetail.find_by_person_id(p.person_id)

        p['first_name'] = '' if p['first_name'].match('@')
        p['last_name'] = '' if p['last_name'].match('@')
        p['middle_name'] = '' if p['middle_name'].match('@')

        name          = ("#{p['first_name']} #{p['middle_name']} #{p['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")

        arr = [
            p.ben,
            details.brn]

        national_id = p.id_number rescue ""
        arr  << (national_id) if ["Print Certificate", "Re-print Certificates"].include?(@section)

        unless national_id.blank?
          nid = ActiveRecord::Base.connection.select_one <<EOF
          SELECT * FROM nid_verification_data WHERE person_id = #{p.person_id} ORDER BY id DESC;
EOF

          if nid['passed'].to_i == 0
            nid_data << nid['person_id'].to_i
          end unless (nid.blank? || !details.brn.blank?)

        end
        arr = arr + [name,
            p.birthdate.strftime('%d/%b/%Y'),
            p.gender,
            mother_name,
            father_name,
            Status.find(p.status_id).name,
            p.person_id
        ]

        @records << arr
      end

      render :text => {
          "draw" => params[:draw].to_i,
          "recordsTotal" => total,
          "recordsFiltered" => total,
          "failed_nids" => nid_data,
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

    print_and_redirect()

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

  def get_ta_complete
    district_name = params[:district]
    nationality_tag = LocationTag.where(name: 'Traditional Authority').first
    location_id_for_district = Location.where(name: district_name).first.id

    data = [['', '']]
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ? AND parent_location = ?",
                   "#{params[:search]}%", nationality_tag.id, location_id_for_district).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << [l.id, l.name]
    end

    render text: data.to_json
  end

  def get_village_complete
    district_name = params[:district]
    location_id_for_district = Location.where(name: district_name).first.id

    ta_name = params[:ta]
    location_id_for_ta = Location.where("name = ? AND parent_location = ?",
                                        ta_name, location_id_for_district).first.id


    nationality_tag = LocationTag.where(name: 'Village').first
    data = [['', '']]
    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND m.location_tag_id = ?
      AND parent_location = ?", "#{params[:search]}%", nationality_tag.id,
                   location_id_for_ta).joins("INNER JOIN location_tag_map m
      ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << [l.id, l.name]
    end

    render text: data.to_json
  end

  def get_hospital_complete
    map =  {'Mzuzu City' => 'Mzimba',
            'Lilongwe City' => 'Lilongwe',
            'Zomba City' => 'Zomba',
            'Blantyre City' => 'Blantyre'}

    if  (params[:district].match(/City$/) rescue false)
      params[:district] =map[params[:district]]
    end

    nationality_tag = LocationTag.where("name = 'Hospital' OR name = 'Health Facility'").first
    data = [['', '']]
    parent_location = Location.where(" name = '#{params[:district]}' AND COALESCE(code, '') != '' ").first.id rescue nil

    Location.where("LENGTH(name) > 0 AND name LIKE (?) AND parent_location = #{parent_location} AND m.location_tag_id = ?",
                   "#{params[:search]}%", nationality_tag.id).joins("INNER JOIN location_tag_map m
    ON location.location_id = m.location_id").order('name ASC').map do |l|
      data << [l.id, l.name]
    end

    render text: data.to_json
  end

  #########################################################################
  def tasks

    session[:district] = ""
    session[:category] = ""

    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
              ["Manage Cases","Manage Cases" , [], "/person/manage_cases","/assets/folder3.png"],
              ["Print Cases", "Printed records", [],"/person/print_cases","/assets/folder3.png"],
              ["Rejected Cases" , "Rejected Cases" , [],"/person/rejected_cases","/assets/folder3.png"],
              ["Edited records from DC" , "Edited records from DC" , ['HQ-RE-APPROVED'],"/person/view","/assets/folder3.png"],
              ["Special Cases" ,"Special Cases" , [],"/person/special_cases","/assets/folder3.png" ],
              ["Verify Certificates", "Verify Certificates", ["HQ-PRINTED"],"/person/view","/assets/folder3.png"],
              ["Duplicate Cases" , "Duplicate cases" , [],"/person/duplicates_menu","/assets/folder3.png"],
              ["Amendment Cases" , "Amendment Cases" , [],"/person/amendments","/assets/folder3.png"],
              ["Print Out" , "Print outs" , [],"/person/print_out","/assets/folder3.png"]
            ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Task(s)"
  end

  def amendments
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = []

    if SETTINGS['enable_role_privileges'] && User.current.user_role.role.role == "Data Supervisor"
         @tasks << ["Lost/Damaged", "Lost/Damaged", ["HQ-LOST", "HQ-DAMAGED"],"/person/view","/assets/folder3.png"]
         @tasks << ["Amendments", "Amendments", ["HQ-AMEND"], "/person/view","/assets/folder3.png"]
         @tasks << ["Rejected Amended by DM", "Rejected Amended by DM", ["HQ-AMEND-REJECTED","HQ-DAMAGED-REJECTED","HQ-LOST-REJECTED"], "/person/view","/assets/folder3.png"]
    elsif SETTINGS['enable_role_privileges'] && User.current.user_role.role.role == "Data Manager"
          @tasks <<  ["Lost/Damaged", "Lost/Damaged", ["HQ-LOST-GRANTED", "HQ-DAMAGED-GRANTED"],"/person/view","/assets/folder3.png"]
          @tasks << ["Amendments", "Amendments", ["HQ-AMEND-GRANTED"], "/person/view","/assets/folder3.png"]
          @tasks << ["Rejected Amended by DS", "Rejected Amended by DS", ["HQ-AMEND-REJECTED-TBA","HQ-DAMAGED-REJECTED-TBA","HQ-LOST-REJECTED-TBA"], "/person/view","/assets/folder3.png"]
          @tasks << ["Closed Amended Records", "Closed Amended Records" , ['HQ-PRINTED', 'HQ-DISPATCHED'],"/person/view?had=HQ-DAMAGED|HQ-LOST|HQ-AMEND","/assets/folder3.png"]
    else
          @tasks <<  ["Lost/Damaged", "Lost/Damaged", ["HQ-LOST", "HQ-DAMAGED","HQ-LOST-GRANTED", "HQ-DAMAGED-GRANTED","HQ-DAMAGED-REJECTED","HQ-LOST-REJECTED"],"/person/view","/assets/folder3.png"]
          @tasks << ["Amendments", "Amendments", ["HQ-AMEND","HQ-AMEND-GRANTED","HQ-AMEND-REJECTED"], "/person/view","/assets/folder3.png"]
          @tasks << ["Closed Amended Records", "Closed Amended Records" , ['HQ-PRINTED', 'HQ-DISPATCHED'],"/person/view?had=HQ-DAMAGED|HQ-LOST|HQ-AMEND","/assets/folder3.png"]
          @tasks << ["Rejected Amended by DM", "Rejected Amended by DM", ["HQ-AMEND-REJECTED","HQ-DAMAGED-REJECTED","HQ-LOST-REJECTED"], "/person/view","/assets/folder3.png"]
          @tasks << ["Rejected Amended by DS", "Rejected Amended by DS", ["HQ-AMEND-REJECTED-TBA","HQ-DAMAGED-REJECTED-TBA","HQ-LOST-REJECTED-TBA"], "/person/view","/assets/folder3.png"]
    end
    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.stats
    @section = "Amendment Cases"

    render :template => "/person/tasks"
  end

  def manage_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
              ["Active Records" ,"Record newly arrived from DC", ["HQ-ACTIVE"],"/person/view","/assets/folder3.png"],
              ["Approve for Printing", "Approve for Printing" , ["HQ-COMPLETE", "HQ-CONFLICT"],"/person/view","/assets/folder3.png", 'Data Manager'],
              ["Incomplete Records from DV","Incomplete records from DV" , ["HQ-INCOMPLETE"],"/person/view","/assets/folder3.png"],
              ["View Printed Records", "Printed records", ["HQ-PRINTED"],"/person/view","/assets/folder3.png"],
              ["Dispatched Records", "Dispatched records" , ["HQ-DISPATCHED"],"/person/view","/assets/folder3.png"]
          ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0].strip) }
    @stats = PersonRecordStatus.stats
    @section = "Manage Cases"

    render :template => "/person/tasks"
  end

  def print_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Approve for Printing", "Approve for Printing" , ["HQ-COMPLETE"],"/person/view","/assets/folder3.png", 'Data Manager'],
        ["Print Certificate","Incomplete records from DV" , ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
        ["Re-print Certificates", "Re-print certificates", ["HQ-CAN-RE-PRINT"],"/person/view","/assets/folder3.png"],
        ["Approve Re-print from QS", "Approve Re-print from QS" , ["HQ-RE-PRINT"],"/person/view","/assets/folder3.png"],
        ["Closed Re-printed Certificates", "Closed Re-printed Certificates" , ["HQ-DISPATCHED"],"/person/view?had=HQ-RE-PRINT","/assets/folder3.png"]
    ]

    @tasks = @tasks.reject{|task| !@folders.include?(task[0].strip) }
    @stats = PersonRecordStatus.stats

    @stats1 = PersonRecordStatus.had_stats('HQ-RE-PRINT')
    @stats['HQ-DISPATCHED'] = @stats1['HQ-DISPATCHED']

    @section = "Print Cases"

    render :template => "/person/tasks"
  end

  def ammend_case
    @person = Person.find(params[:id])

    @status = PersonRecordStatus.status(@person.id)
    if @status != "DC-AMEND"
       #PersonRecordStatus.new_record_state(params['id'], "DC-AMEND", "Amendment request; #{params['reason']}")
    end
    @comments = PersonRecordStatus.where(" person_id = #{@person.id} AND COALESCE(comments, '') != '' ")
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, [@status])
    @prev_details = {}
    @birth_details = PersonBirthDetail.where(person_id: params[:id]).last

    @name = @person.person_names.last
    @person_prev_values = {}
    name_fields = ['first_name','last_name','middle_name',"gender","birthdate","birth_location_id"]
    name_fields.each do |field|
        trail = AuditTrail.where(person_id: params[:id], field: field).order('created_at').last
        if trail.present?
            @person_prev_values[field] = trail.previous_value
        end
    end

    if @person_prev_values['first_name'].present? || @person_prev_values['last_name'].present?
        name = "#{@person_prev_values['first_name'].present? ? @person_prev_values['first_name'] : @name.first_name} "+
               "#{@person_prev_values['middle_name'].present? ? @person_prev_values['middle_name'] : (@name.middle_name rescue '')} " +
               "#{@person_prev_values['last_name'].present? ? @person_prev_values['last_name'] : @name.last_name}"
        @person_prev_values["person_name"] = name
    end
    @address = @person.addresses.last

    @mother_person = @person.mother
    @mother_name = @mother_person.person_names.last rescue nil
    @mother_prev_values = {}
    name_fields.each do |field|
        trail = AuditTrail.where(person_id: @mother_person.id, field: field).order('created_at').last
        if trail.present?
            @mother_prev_values[field] = trail.previous_value
        end
    end

    if @mother_prev_values['first_name'].present? || @mother_prev_values['last_name'].present?
        mother_name = "#{@mother_prev_values['first_name'].present? ? @mother_prev_values['first_name'] : @mother_name.first_name} "+
               "#{@mother_prev_values['middle_name'].present? ? @mother_prev_values['middle_name'] : (@mother_name.middle_name rescue '')} " +
               "#{@mother_prev_values['last_name'].present? ? @mother_prev_values['last_name'] : @mother_name.last_name}"
        @person_prev_values["mother_name"] = mother_name
    end

    @father_person = @person.father
    @father_name = @father_person.person_names.last rescue nil

    @father_prev_values = {}
    name_fields.each do |field|
        break if @father_person.blank?
        trail = AuditTrail.where(person_id: @father_person.id, field: field).order('created_at').last

        if trail.present?
            @father_prev_values[field] = trail.previous_value
        end
    end

    if @father_prev_values['first_name'].present? || @father_prev_values['last_name'].present?
        father_name = "#{@father_prev_values['first_name'].present? ? @father_prev_values['first_name'] : @father_name.first_name} "+
               "#{@father_prev_values['middle_name'].present? ? @father_prev_values['middle_name'] : (@father_name.middle_name rescue '')} " +
               "#{@father_prev_values['last_name'].present? ? @father_prev_values['last_name'] : @father_name.last_name}"
        @person_prev_values["father_name"] = father_name
    end
    @section = 'Ammend Case'
  end

  def print_out
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Approve for Printing" ,"All records pending Approval to generate Registration Number", ["HQ-COMPLETE"],"/person/view","/assets/folder3.png"],
        ["Print Certificates", "All records pending to be printed " , ["HQ-CAN-PRINT"],"/person/view","/assets/folder3.png"],
        ["Re-print Certificates", "Conflict Cases" , ["HQ-CAN-RE-PRINT","HQ-CAN-REPRINT-AMEND"],"/person/view","/assets/folder3.png"],
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
        ["Approved for Printing" ,"Approved for Printing", ["HQ-CAN-PRINT", "HQ-PRINTED", "HQ-DISPATCHED", "HQ-CAN-RE-PRINT"],
          "/person/view?had=HQ-INCOMPLETE-TBA&had_by=Data Supervisor","/assets/folder3.png"],
        ["Incomplete Cases" ,"Incomplete Cases", ["HQ-INCOMPLETE-TBA", "HQ-CONFLICT"],"/person/view","/assets/folder3.png"],
        ["Rejected records" ,"Rejected records", ["HQ-CAN-REJECT"],"/person/view","/assets/folder3.png"],
      ]

    @tasks.reject{|task| !@folders.include?(task[0]) }

    @stats = PersonRecordStatus.had_stats('HQ-INCOMPLETE', 'Data Checking Clerk')
    @stats1 = PersonRecordStatus.stats
    @stats['HQ-INCOMPLETE-TBA'] = @stats1['HQ-INCOMPLETE-TBA']
    @stats['HQ-CONFLICT'] = @stats1['HQ-CONFLICT']
    @stats['HQ-CAN-REJECT'] = @stats1['HQ-CAN-REJECT']

    @section = "Rejected Cases"

    render :template => "/person/tasks"
  end

  def special_cases
    @folders = ActionMatrix.read_folders(User.current.user_role.role.role)
    @tasks = [
        ["Abandoned Cases" ,"All records that were registered as Abandoned ", [],"/person/view?birth_type=Abandoned","/assets/folder3.png"],
        ["Adopted Cases", "All records that were registered as Adopted" , [],"/person/view?birth_type=Adopted","/assets/folder3.png"],
        ["Orphaned cases", "All records that were registered as Orphaned" , [],"/person/view?birth_type=Orphaned","/assets/folder3.png"],
        ["Printed/Dispatched Certificates", "All approved and printed Special cases", ['HQ-PRINTED', 'HQ-DISPATCHED'],"/person/view?birth_type=All Special Cases","/assets/folder3.png"]
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
    paper_size = GlobalProperty.find_by_property("paper_size").value rescue 'A4'

    if paper_size == "A4"
      zoom = 0.83
    elsif paper_size == "A5"
      zoom = 0.89
    end

    person_ids = params[:person_ids].split(',')
    person_ids.each do |person_id|
      #begin
        PersonRecordStatus.new_record_state(person_id, 'HQ-PRINTED', 'Printed Child Record')
        print_url = "wkhtmltopdf --zoom #{zoom} --page-size #{paper_size} #{SETTINGS["protocol"]}://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/birth_certificate?person_ids=#{person_id.strip} #{SETTINGS['certificates_path']}#{person_id.strip}.pdf\n"

        puts print_url

        t4 = Thread.new {
          Kernel.system print_url
          sleep(4)
          Kernel.system "lp -d #{params[:printer_name]} #{SETTINGS['certificates_path'].strip}#{person_id.strip}.pdf\n"
          sleep(5)
        }
        sleep(1)

      #rescue => e
        #print_errors[person_id] = e.message + ":" + e.backtrace.inspect
      ##end
    end

    if print_errors.present?
      print_errors.each do |k,v|
        print_error_log.debug "#{k} : #{v}"
      end
    end

    if !session[:list_url].blank?
      redirect_to session[:list_url]
    else
      redirect_to "/"
    end
  end

  def print_preview
    @section = "Print Preview"
    @available_printers = SETTINGS["printer_name"].split('|')
    render :layout => false
  end

  def birth_certificate

    @data = []
    signatory = User.find_by_username(GlobalProperty.find_by_property("signatory").value) rescue nil
    signatory_attribute_type = PersonAttributeType.find_by_name("Signature") if signatory.present?
    @signature = PersonAttribute.find_by_person_id_and_person_attribute_type_id(signatory.id,signatory_attribute_type.id).value rescue nil

    person_ids = params[:person_ids].split(',')
    nid_type = PersonIdentifierType.where(name: "Barcode Number").last

    person_ids.each do |person_id|
      data = {}
      data['person'] = Person.find(person_id) rescue nil
      data['birth']  = PersonBirthDetail.where(person_id: person_id).last
      
      barcode = File.read("#{SETTINGS['barcodes_path']}#{person_id}.png") rescue nil
      if barcode.nil?

    	  barcode_value = PersonIdentifier.where(person_id: person_id,
						person_identifier_type_id: nid_type.id
					).last.value rescue nil

        if barcode_value.blank?

          bcd = BarcodeIdentifier.where(assigned: 0).first
          bcd.person_id = person_id
          bcd.assigned  = 1
          bcd.save

          p = PersonIdentifier.new
          p.person_id = person_id
          p.value = bcd.value
          p.person_identifier_type_id = PersonIdentifierType.where(name: "Barcode Number").last.id
          p.save

          barcode_value = bcd.value
        end

        `bundle exec rails r bin/generate_barcode #{ barcode_value } #{ data['person'].id} #{SETTINGS['barcodes_path']} -e #{Rails.env}  `
      end

      data['barcode'] = File.read("#{SETTINGS['barcodes_path']}#{person_id}.png")

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
              ["Confirmed Duplicates","Confirmed Duplicate" , ["HQ-VOIDED DUPLICATE","HQ-VOIDED"],"/person/view?had=HQ-DUPLICATE","/assets/folder3.png"],
              ["Resolve Potential Duplicates","Resolve Potential Duplicates" , ["HQ-POTENTIAL DUPLICATE-TBA","HQ-NOT DUPLICATE-TBA"],"/person/view","/assets/folder3.png"],
              ["Approved for Printing","Approved for printing" , ['HQ-CAN-PRINT'],"/person/view?had=HQ-POTENTIAL DUPLICATE","/assets/folder3.png"],
              ["Voided Records","Voided Records" , ["HQ-VOIDED"],"/person/view?had=HQ-POTENTIAL DUPLICATE-TBA","/assets/folder3.png"]
            ]
    @tasks = @tasks.reject{|task| !@folders.include?(task[0]) }
    @section = "Manage duplicate"

    @had_stats = PersonRecordStatus.had_stats('HQ-POTENTIAL DUPLICATE', nil)
    @had_stats2 = PersonRecordStatus.had_stats('HQ-POTENTIAL DUPLICATE-TBA', nil)
    @stats = PersonRecordStatus.stats
    @stats['HQ-CAN-PRINT'] = @had_stats['HQ-CAN-PRINT']
    @stats['HQ-VOIDED'] = @had_stats['HQ-VOIDED']

    render :template => "/person/tasks"
  end
  def duplicate
    @section = "Manage Duplicates"
    @operation = "Resolve"
    @potential_duplicate =  person_details(params[:person_id])
    @potential_records = PotentialDuplicate.where(:person_id => (params[:person_id].to_i)).last
    @similar_records = []
    @comments = PersonRecordStatus.where(" person_id = #{params[:person_id]} AND COALESCE(comments, '') != '' ")
    @status = PersonRecordStatus.status(params[:person_id])
    @actions = ActionMatrix.read_actions(User.current.user_role.role.role, [@status])
    @potential_records.duplicate_records.each do |record|
      @similar_records << person_details(record.person_id)
    end
  end

  def duplicate_processing
    if params[:operation] == "System"
      PersonRecordStatus.new_record_state(params[:id], "HQ-POTENTIAL DUPLICATE",  (params[:comment].present? ? params[:comment] : "System marked record as duplicate" ))
      redirect_to params[:next_url].to_s
    elsif params[:operation] =="Resolve"
         potential_record = PotentialDuplicate.where(:person_id => (params[:id].to_i)).last

         if potential_record.present?
            if params[:decision] == "NOT DUPLICATE"
              PersonRecordStatus.new_record_state(params[:id], 'HQ-CAN-PRINT', params[:comment])
            else
                PersonRecordStatus.new_record_state(params[:id], 'HQ-DUPLICATE', params[:comment])
            end
            potential_record.resolved = 1
            potential_record.decision = params[:decision]
            potential_record.comment = params[:comment]
            potential_record.resolved_at = Time.now
            potential_record.save
        end
        redirect_to "/person/view?statuses[]=HQ-POTENTIAL DUPLICATE-TBA&statuses[]=HQ-NOT DUPLICATE-TBA&destination=Resolve Potential Duplicates"

    elsif params[:operation] == "Confirm-duplicate"

        potential_record = PotentialDuplicate.where(:person_id => (params[:id].to_i)).last
        if potential_record.present?
            if params[:decision] == "NOT DUPLICATE"
                PersonRecordStatus.new_record_state(params[:id], 'HQ-NOT DUPLICATE-TBA', params[:comment])
            else
               PersonRecordStatus.new_record_state(params[:id], 'HQ-POTENTIAL DUPLICATE-TBA', params[:comment])
            end
        end
        redirect_to "/person/view?statuses[]=HQ-POTENTIAL DUPLICATE&destination=Potential Duplicate"

    elsif params[:operation] == "Void-duplicate"

        PersonRecordStatus.new_record_state(params[:id], 'HQ-VOIDED', params[:comment])
        redirect_to "/person/view?statuses[]=HQ-DUPLICATE&destination=Duplicate Cases"

    elsif params[:operation] == "Verify-DC"
        potential_record = PotentialDuplicate.where(:person_id => (params[:id].to_i)).last
        duplicates = potential_record.duplicate_records
        comment = "Record is duplicate with #{duplicates.count} record(s)<br/><ol>"
        duplicates.each do |dup|
            details = person_details(dup.person_id).with_indifferent_access
            comment = comment + "<li>#{details[:first_name]} #{details[:middle_name] rescue ''} #{details[:last_name]} BEN : #{details[:birth_entry_number]}</li>".squish
        end
        comment = comment + "</ol><b>#{params[:comment]}</b>"

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



    person_name = PersonName.find_by_person_id(id)
    person = Person.find(id)

    core_person = CorePerson.find(id)
    birth_details = PersonBirthDetail.find_by_person_id(id)

    person_record_status = PersonRecordStatus.where(:person_id => id).last
    person_status = person_record_status.status.name rescue nil

    actions = ActionMatrix.read_actions(User.current.user_role.role.role, [person_status]) rescue nil


    #mother = Person.find(mother_id)
    #mother_name = PersonName.find_by_person_id(mother_id)

    mother = person.mother
    mother_address = mother.addresses.last rescue nil
    mother_name = mother.person_names.last rescue nil

    father = person.father
    father_address = father.addresses.last rescue nil
    father_name = father.person_names.last rescue nil


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
		time = Time.now
    @people.each do |person|
      s = PersonRecordStatus.new_record_state(person.id, 'HQ-DISPATCHED')
			s.created_at = time
			s.save
    end

    path = "#{SETTINGS['certificates_path']}dispatch_#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"

    print_url = "wkhtmltopdf 	--orientation landscape --page-size A4 #{SETTINGS["protocol"]}://#{request.env["SERVER_NAME"]}:#{request.env["SERVER_PORT"]}/person/dispatch_list?person_ids=#{params[:person_ids]} #{path}.pdf\n"

    t4 = Thread.new {
      Kernel.system print_url
      sleep(3)
      Kernel.system "lp -d #{params[:printer_name]} #{path}.pdf\n"
    }
    sleep(1)

    redirect_to session[:list_url]
  end

  def dispatch_list
    @people = Person.find_by_sql("SELECT n.*, p.gender, p.birthdate, d.national_serial_number, d.district_id_number, d.date_registered, d.location_created_at FROM person p
                                 INNER JOIN person_birth_details d ON d.person_id = p.person_id
                                 INNER JOIN person_name n ON n.person_id = p.person_id
                        WHERE d.person_id IN (#{params[:person_ids]}) ")
    @districts = []

    #Unify dispatch time
    dispatch_time = PersonRecordStatus.find_by_sql("SELECT MAX(created_at) m FROM person_record_statuses WHERE person_id IN (#{params[:person_ids]})
                      AND status_id = (SELECT status_id FROM statuses WHERE name = 'HQ-DISPATCHED' LIMIT 1) ").last.as_json['m']

    PersonRecordStatus.where("person_id IN (#{params[:person_ids]}) AND status_id = (SELECT status_id FROM statuses WHERE name = 'HQ-DISPATCHED') ").each do |s|
      s.update_attribute('created_at', dispatch_time)
    end

    @data = []
    @people.each do |p|

      @districts <<  Location.find(@people.first.location_created_at).district
      details = PersonBirthDetail.where(:person_id => p.person_id).last

      @data << {
          'name'                => p.name,
          'brn'                 => details.brn,
          'ben'                 => details.ben,
          'dob'                 => p.birthdate.to_date.strftime('%d/%b/%Y'),
          'sex'                 => p.gender,
          'place_of_birth'      => details.birthplace,
          'date_registered'     => (p.date_registered.to_date.strftime('%d/%b/%Y') rescue nil)
      }
    end

    @districts = @districts.uniq
    @district = @districts.join(", ")

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
          date_registered:     (p.date_registered.to_date.strftime('%d/%b/%Y') rescue nil)
      }
    end

    render text: data.to_json
  end

  def map_main

    @sites = []
    @sites_enabled = []

    files = Dir.glob( File.join("#{Rails.root}/public/sites", '**', '*.yml')).to_a
    (files || []).each do |f|
      sites = YAML.load_file(f) rescue {}
      (sites || []).each do |site_id, site|
        l = Location.find(site_id) rescue nil
        next if l.blank?
        @sites_enabled << l

        site['online'] = sites[site_id]['online'] rescue false
        last_seen =  sites[site_id]['last_seen'].to_datetime rescue nil

        if last_seen.present?
          months_diff = ((Time.now - last_seen.to_time)/(60*60*24*30)).to_i
          days_diff = ((Time.now - last_seen.to_time)/(60*60*24)).to_i
          hrs_diff = ((Time.now - last_seen.to_time)/(60*60)).to_i
          min_diff = ((Time.now - last_seen.to_time)/(60)).to_i
          sec_diff = (Time.now - last_seen.to_time).to_i

          if site['online']
            last_seen = "<span style='color: green !important'>Online</span>".html_safe
          elsif months_diff > 0
            last_seen = "#{months_diff} months ago"
          elsif days_diff > 0
            last_seen = "#{days_diff} days ago"
          elsif hrs_diff > 0
            last_seen = "#{hrs_diff} hrs ago"
          elsif min_diff > 0
            last_seen = "#{min_diff} mins ago"
          else
            last_seen = "#{sec_diff} secs ago"
          end
        else
          last_seen = "<span style='color: red !important'>Offline</span>".html_safe
        end


        @sites << {
            'online' => (site['online'] rescue false),
            'region' => l.description,
            'x' => l.latitude.to_f,
            'y' => l.longitude.to_f,
            'sitecode' => l.code,
            'location_id' => l.id,
            'name' => l.name,
            'last_seen' => last_seen,
            'district' => l.district.downcase.gsub(/\-|\_|\s+/, '').strip,
        }
      end
    end

    render :layout => false
  end

  def get_district_stats
    locations = [params[:location_id]]
    facility_tag_id = LocationTag.where(name: 'Health Facility').first.id rescue [-1]
    (Location.find_by_sql("SELECT l.location_id FROM location l
                            INNER JOIN location_tag_map m ON l.location_id = m.location_id AND m.location_tag_id = #{facility_tag_id}
                          WHERE l.parent_location = #{params[:location_id]}") || []).each {|l|
      locations << l.location_id
    }


    stats = PersonRecordStatus.stats(['Normal', 'Adopted', 'Orphaned', 'Abandoned'], true, locations)

    data = [
        ['Newly Received (HQ)', stats['HQ-ACTIVE']],
        ['Print Queue (HQ)', stats['HQ-CAN-PRINT']],
        ['Rejected to DC', stats['HQ-REJECTED']],
        ['Re-print Que (HQ)', (stats['HQ-RE-PRINT'] + stats['HQ-CAN-RE-PRINT'])],
        ['Suspected Duplicate (HQ)', stats['HQ-POTENTIAL DUPLICATE']],
        ['Incomplete Record (HQ)', stats['HQ-INCOMPLETE']],
        ['Printed (HQ)', stats['HQ-PRINTED']],
        ['Dispatched(HQ)', stats['HQ-DISPATCHED']],
        ['Amendment Request (HQ)', stats['HQ-AMEND']],
    ]

    render :text => data.to_json
  end

  def check_details
    result = {}
    barcode = params[:certificate_serial_number]
    ben = barcode if ((barcode.scan("/").length == 2) rescue false)

    nid_type = PersonIdentifierType.where(name: "Barcode Number").last
    person_id = PersonIdentifier.where(value: barcode, person_identifier_type_id: nid_type, voided: 0).last.person_id rescue nil

    person_id = nil
    if person_id.blank?
      nid_type = PersonIdentifierType.where(name: "National ID Number").last
      person_id = PersonIdentifier.where(value: barcode, person_identifier_type_id: nid_type, voided: 0).last.person_id rescue nil
    end

    if person_id.blank?
      nid_type = PersonIdentifierType.where(name: "Birth Registration Number").last
      person_id = PersonBirthDetail.where(national_serial_number: barcode).last.person_id rescue nil
      person_id = PersonIdentifier.where(value: barcode, person_identifier_type_id: nid_type, voided: 0).last.person_id rescue nil if person_id.blank?

      if person_id.blank? && !ben.blank?
        person_id = PersonBirthDetail.where(district_id_number: ben).last.person_id rescue nil

        if person_id.blank?
         person_id = PersonIdentifier.where(person_identifier_type_id: PersonIdentifierType.where(name: "Old Birth Entry Number", value: ben).last.id).last.person_id rescue nil
        end
      end
    end

    return person_id
  end

  def certificate_verification
    @section = "Verify Certificates"

    if request.post?
      person_id = check_details
      if person_id.blank?
        flash[:error] = "Record Not Found!"
      elsif params[:verdict] == "No"
        PersonRecordStatus.new_record_state(person_id, "HQ-RE-PRINT", params['reason'])
      end
    end

    #render layout: "touch"
  end

  def sync_status
    render :text => PersonBirthDetail.record_available?(params[:person_id])
  end

  def ajax_request_national_id
    person_id = params[:person_id]
    result = PersonService.request_nris_id(person_id, request.remote_ip, User.current)

    if result == true || result == "NOT A MALAWIAN CITIZEN" || result == "AGE LIMIT EXCEEDED" || "NID INTEGRATION NOT ACTIVATED"
      render plain: "OK"
    else
      render plain: "PENDING"
    end
  end

  def ajax_check_brn
    person_id = params[:person_id]
    birth = PersonBirthDetail.where(person_id: person_id).first

    if !birth.blank? && !birth.national_serial_number.blank?
            barcode = BarcodeIdentifier.where(:assigned => 0).last
						idf = PersonIdentifier.where(person_id: person_id, 
								person_identifier_type_id: PersonIdentifierType.where(name: "Barcode Number").last.id,
								voided: 0
						).first 

            if !barcode.blank? && idf.blank?

              p = PersonIdentifier.new
              p.person_id = person_id
              p.value = barcode.value
              p.person_identifier_type_id = PersonIdentifierType.where(name: "Barcode Number").last.id
              t1 = p.save rescue false

              if t1 == false
                p = PersonIdentifier.new
                p.person_id = person_id
                p.value = barcode.value
                p.person_identifier_type_id = PersonIdentifierType.where(name: "Barcode Number").last.id
                p.save
              end

              barcode.update_attributes(assigned: 1,
                                        person_id: person_id)
            end
      

      render plain: "OK"
    else
      workers = SuckerPunch::Queue.stats["AllocationQueue"]["workers"] rescue nil
      if workers.blank? || workers["total"] == 0 || workers["busy"] > 0
        AllocationQueue.perform_in(1)
      end

      render plain: "PENDING"
    end
  end

end
