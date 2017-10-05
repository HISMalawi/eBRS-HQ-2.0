require 'csv'
require'migration-lib/lib'
require'migration-lib/person_service'
@file_path = "#{Rails.root}/app/assets/data/"
@multiple_births = "#{Rails.root}/app/assets/data/multiple_births.csv"
@missing_prev_child_id = "#{Rails.root}/app/assets/data/missing_previous_child_id.txt"
@suspected = "#{Rails.root}/app/assets/data/suspected.txt"


User.current = User.last

Duplicate_attribute_type_id = PersonAttributeType.where(name: 'Duplicate Ben').first.id

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

def write_log(file_path,content)

	if !File.exists?(file_path)
           file = File.new(file_path, 'w')
    else
       File.open(file_path, 'a') do |f|
          f.puts "#{content}"
      end
    end
end

def transform_data(data, ids)
    
	unless data[:person][:multiple_birth_id].blank?
	    data[:person][:prev_child_id] = ids[data[:person][:multiple_birth_id]]
	    
	      if !data[:person][:prev_child_id].blank?
              save_full_record(data, data[:person][:district_id_number])	
	      else
              write_log(@missing_prev_child_id,data)
	      end
	else
		 #=============== multiple_birth_id missing, log this record to suspected file for further analysis
		 write_log(@suspected,data)
	end    
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

def get_record_status(rec_status, req_status)


 status = {"DC OPEN" => {'ACTIVE' =>'DC-ACTIVE',
      							'IN-COMPLETE' =>'DC-INCOMPLETE',
      							'COMPLETE' =>'DC-COMPLETE',
      							'DUPLICATE' =>'DC-DUPLICATE',
      							'POTENTIAL DUPLICATE' =>'DC-POTENTIAL DUPLICATE',
      							'GRANTED' =>'DC-GRANTED',
      							'PENDING' => 'DC-PENDING',
      							'CAN-REPRINT' => 'DC-CAN-REPRINT',
      							'REJECTED' =>'DC-REJECTED'},
		"POTENTIAL DUPLICATE" => {'ACTIVE' =>'FC-POTENTIAL DUPLICATE'},
		"POTENTIAL-DUPLICATE" =>{'VOIDED'=>'DC-VOIDED'},
		"VOIDED" =>{'CLOSED' =>'DC-VOIDED',
					'CLOSED' =>'HQ-VOIDED'},
		"PRINTED" =>{'CLOSED' =>'HQ-PRINTED',
					'DISPATCHED' =>'HQ-DISPATCHED'},
		"HQ-PRINTED" =>{'CLOSED' =>'HQ-PRINTED'},
		"HQ-DISPATCHED" =>{'DISPATCHED' =>'HQ-DISPATCHED'},
		"HQ-CAN-PRINT" =>{'CAN PRINT' =>'HQ-CAN-REPRINT'},
		"HQ OPEN" =>{'ACTIVE' =>'HQ-ACTIVE',
					'RE-APPROVED' =>'HQ-RE-APPROVED',
					'DC_ASK' =>'DC-ASK',
					'GRANTED' =>'HQ-GRANTED',
					'REJECTED' =>'HQ-REJECTED',
					'COMPLETE' =>'HQ-INCOMPLETE-TBA',
					'COMPLETE' =>'HQ-COMPLETE',
					'CAN PRINT' =>'HQ-CAN-PRINT',
					'CAN REJECT' =>'HQ-CAN-REJECT',
					'APPROVED' =>'HQ-APPROVED',
					'TBA-CONFLICT' =>'HQ-CONFLICT',
					'TBA-POTENTIAL DUPLICATE' =>'HQ-POTENTIAL DUPLICATE-TBA',
					'CAN VOID' =>'HQ-CAN-VOID',
					'INCOMPLETE' =>'HQ-INCOMPLETE',
					'RE-PRINT' =>'HQ-RE-PRINT',
					'CAN RE_PRINT' =>'HQ-CAN-RE-PRINT',
					'POTENTIAL DUPLICATE' =>'HQ-POTENTIAL DUPLICATE'},
		"DUPLICATE" =>{'VOIDED' =>'HQ-VOIDED'}}


   return status[rec_status][req_status]

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

   begin
        params[:record_status] = get_record_status(params[:record_status],params[:request_status]).upcase.squish!
    	person = PersonService.create_record(params)

      if !person.blank?
        
        record_status = PersonRecordStatus.where(person_id: person.person_id).first
        
        	#status = get_record_status(params[:record_status],params[:request_status]).upcase.squish!
	        #record_status.update_attributes(status_id: Status.where(name: status).last.id)
	    assign_district_id(person.person_id, (district_id_number.to_s rescue "NULL"))
	    puts "Record for #{params[:person][:first_name]} #{params[:person][:middle_name]} #{params[:person][:last_name]} Created ............. "

        
      end

   rescue StandardError => e
          log_error(e.message, params)
   end

end

def build_client_record(current_pge, pge_size)

  data ={}

  records = Child.all.page(current_pge).limit(pge_size)

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
				   created_at: r[:created_at],
				   created_by: r[:created_by],
				   updated_at: r[:updated_at], 
				   parents_signed: "",
				   national_serial_number: r[:national_serial_number],
				   district_id_number: r[:district_id_number],
				   prev_child_id: "",
				   multiple_birth_id: r[:multiple_birth_id],
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

def initiate_migration

    total_records = Child.count
	page_size = 100
	total_pages = (total_records / page_size) + (total_records % page_size)
	current_page = 1

	while (current_page < total_pages) do

        build_client_record(current_page, page_size)
        current_page = current_page + 1
	end

    puts "\n"
    puts "Completed migrating the data! To verify the completeness of this process, please review the log files.. Thank you!!"
    puts "\n"

end

initiate_migration
