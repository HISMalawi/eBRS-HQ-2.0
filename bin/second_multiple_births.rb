require 'csv'
require'migration-lib/lib'
require'migration-lib/person_service'
@file_path = "#{Rails.root}/app/assets/data/"
@multiple_births = "#{Rails.root}/app/assets/data/multiple_births.csv"

def get_prev_child_id

   data = {}

    CSV.foreach("#{@file_path}/multiple_births.csv") do |row|
         data[row[0]] = row[1]     
    end

  return data
end

def log_error(error_msge, content)

    file_path = "#{Rails.root}/app/assets/data/error_log.txt"
    if !File.exists?(file_path)
           file = File.new(file_path, 'w')
    else

       File.open(file_path, 'a') do |f|
          f.puts "#{error_msge} >>>>>> #{content}"

      end
    end

 end

def transform_data(data, ids)

	case data[:registration_type]
       when "adopted"
       	if !data[:person][:mother][:first_name].blank? && !data[:person][:mother][:last_name].blank? && !data[:person][:father][:first_name].blank? && !data[:person][:father][:last_name].blank?
       		data[:biological_parents] = "Both"
       	end
       	if !data[:person][:mother][:first_name].blank? && data[:person][:father][:first_name].blank?
       		data[:biological_parents] = "Mother"
       	end
       	if  data[:person][:mother][:first_name].blank? && !data[:person][:father][:first_name].blank?
       		data[:biological_parents] = "Father"
       	end
       when "abandoned"
       	if !data[:person][:mother][:first_name].blank? && !data[:person][:mother][:last_name].blank? && !data[:person][:father][:first_name].blank? && !data[:person][:father][:last_name].blank?
       	    data[:parents_details_available] = "Both"
       	end
        if !data[:person][:mother][:first_name].blank? && data[:person][:father][:first_name].blank?
       		data[:parents_details_available] = "Mother"
       	end
       	if  data[:person][:mother][:first_name].blank? && !data[:person][:father][:first_name].blank?
       		data[:parents_details_available] = "Father"
       	end
    else
    end
    
    #==================== Transform the citizenship if not complying with those specified in the metadata
    data[:person][:mother][:citizenship] ="Mozambican" if data[:person][:mother][:citizenship] =="Mozambique"
    data[:person][:mother][:citizenship] ="Malawian" if data[:person][:mother][:citizenship].blank?
    
	if !data[:person][:multiple_birth_id].blank?
	    data[:person][:prev_child_id] = ids[data[:person][:multiple_birth_id]]
	    save_full_record(data, data[:person][:district_id_number])	
	else
		 #multiple_birth_id missing, log this record to suspected file for further analysis
	end

    return record
end

def assign_district_id(person_id, ben)

	ben_exist = PersonBirthDetail.where(district_id_number: ben)

	if ben_exist.blank?
		birth_details = PersonBirthDetail.where(person_id: person_id).first
	    birth_details.update_attributes(district_id_number: ben)

	else
		PersonAttribute.create(value: ben, person_id: person_id, person_attribute_type_id: Duplicate_attribute_type_id )
		(ben_exist || []).each do |r|
			r.update_attributes(district_id_number: nil)
			PersonAttribute.create(value: ben, person_id: r.person_id, person_attribute_type_id: Duplicate_attribute_type_id)
		 end
	end

end

def save_full_record(params, district_id_number)

    if !district_id_number.blank?

    	person = PersonService.create_record(params)

      if person.present?
        
        record_status = PersonRecordStatus.where(person_id: person.person_id).first
        begin
	        record_status.update_attributes(status_id: Status.where(name: get_record_status(params[:record_status],params[:request_status])).last.id)
	        assign_district_id(person.person_id, (district_id_number.to_s rescue nil))
	        puts "Record for #{params[:person][:first_name]} #{params[:person][:middle_name]} #{params[:person][:last_name]} Created ............. "
        rescue StandardError => e
            log_error(e.message, params)
        end
        
      end
    else
    	 write_log(@suspected,params)
    end
end

def build_client_record

  data ={}
  records = Child.all.limit(10).each

  (records || []).each do |r|

   data = { person: {duplicate: "", is_exact_duplicate: "", 
				   relationship: r[:relationship], 
				   last_name: r[:last_name], 
				   first_name: r[:first_name], 
				   middle_name: r[:middle_name], 
				   birthdate: r[:birthdate], 
				   birth_district: r[:birth_district], 
				   gender: r[:gender], 
				   place_of_birth: r[:place_of_birth], 
				   hospital_of_birth: r[:hospital_of_birth], 
				   birth_weight: r[:birth_weight], 
				   type_of_birth: r[:type_of_birth], 
				   parents_married_to_each_other: r[:parents_married_to_each_other], 
				   court_order_attached: r[:court_order_attached], 
				   parents_signed: "",
				   national_serial_number: r[:national_serial_number],
				   district_id_number: r[:district_id_number],
				   prev_child_id: "", 
				   mother:{
				     last_name: r[:mother][:last_name], 
				     first_name: r[:mother][:first_name], 
				     middle_name: r[:mother][:middle_name], 
				     birthdate: r[:mother][:birthdate], 
				     birthdate_estimated: r[:mother][:birthdate_estimated], 
				     citizenship: r[:mother][:citizenship], 
				     residential_country: r[:mother][:residential_country], 
				     current_district: r[:mother][:current_district], 
				     current_ta: r[:mother][:current_ta], 
				     current_village: r[:mother][:current_village], 
				     home_district: r[:mother][:home_district], 
				     home_ta: r[:mother][:home_ta], 
				     home_village: r[:mother][:home_village]
				  }, 
				   mode_of_delivery: r[:mode_of_delivery], 
				   level_of_education: r[:level_of_education], 
				   father: {
				     birthdate_estimated: r[:father][:birthdate_estimated], 
				     residential_country: r[:father][:residential_country]
				  }, 
				   informant: {
				     last_name: r[:informant][:last_name], 
				     first_name: r[:informant][:first_name], 
				     middle_name: r[:informant][:middle_name], 
				     relationship_to_person: r[:informant][:relationship_to_child], 
				     current_district: r[:informant][:current_district],  
				     current_ta: r[:informant][:current_ta], 
				     current_village: r[:informant][:current_village], 
				     addressline1: r[:informant][:addressline1], 
				     addressline2: r[:informant][:addressline2], 
				     phone_number: r[:informant][:phone_number]
				  }, 
				   form_signed: r[:form_signed], 
				   acknowledgement_of_receipt_date: r[:acknowledgement_of_receipt_date]
				  }, 
				   home_address_same_as_physical: "Yes", 
				   gestation_at_birth: r[:gestation_at_birth], 
				   number_of_prenatal_visits: r[:number_of_prenatal_visits], 
				   month_prenatal_care_started: r[:month_prenatal_care_started], 
				   number_of_children_born_alive_inclusive: r[:number_of_children_born_alive_inclusive], 
				   number_of_children_born_still_alive: r[:number_of_children_born_still_alive], 
				   same_address_with_mother: "", 
				   informant_same_as_mother: (r[:informant][:relationship_to_child] == "Mother" ? "Yes" : "No"), 
				   registration_type: r[:relationship],
				   record_status: r[:record_status],
				   _rev: r[:_rev],
				   _id: r[:_id],
				   request_status: r[:request_status], 
				   copy_mother_name: "No", 
				   controller: "person", 
				   action: "create"
				  }

			
			if ["Second Twin","Second Triplet","Third Triplet"].include? data[:person][:type_of_birth]
            	transform_data(data, get_prev_child_id)
			end
	end
            
end