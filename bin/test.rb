@file_path = "#{Rails.root}/app/assets/data/"
@multiple_births = "#{Rails.root}/app/assets/data/multiple_births.csv"

def write_log(file, content)

	if !File.exists?(file)
           file = File.new(file, 'w')
    else


       File.open(file, 'a') do |f|
          f.puts "#{content}"

      end


    end
end

def get_prev_child_id

   data = {}

    CSV.foreach("#{@file_path}/multiple_births.csv") do |row|
         data[row[0]] = row[1]     
    end

  return data
end

def save_record(record, district_id_number)

end

def transform_data(record, ids)

	if !record[:person][:multiple_birth_id].blank?
	  record[:person][:prev_child_id] = ids[record[:person][:multiple_birth_id]]	
	else
		 #multiple_birth_id missing, log this record to suspected file for further analysis
	end

    return record
end

def get_record_status(rec_status, req_status)
  
    puts "<<<<<<<<<<< #{rec_status}   #{req_status}"
    
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

def func
  
  data ={}
  records = Child.all.limit(20).each
  count = 1
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
				   count: count,
				   request_status: r[:request_status], 
				   copy_mother_name: "No", 
				   controller: "person", 
				   action: "create"
				  }
=begin            
            if ["Twin","Triplet","Second Twin","Second Triplet","Third Triplet"].include? data[:person][:type_of_birth]
            	if data[:person][:type_of_birth] == "Twin" || data[:person][:type_of_birth] == "Triplet"
            		 row = "#{data[:person][:type_of_birth]},#{data[:_id]},"
            	     write_log(@multiple_births, row)
            	else
            	    #1. build a json object
            	    #2. read the multiple_birth csv and populate the hash
            	    #3. fetch records filter them by type_of_birth. Type of birth should be equal
            	    #   Second Twin,Second Triplet or Third Triplet
            	    #4. from each record filtered, use the multiple_birth_id to lookup in the hash
            	    #   and pick the person_id
            	    #5. change the value of data[:person][:prev_child_id]= person_id
            	    #6. call the PersonService.create_record method...
            	    #7. change the PersonAttribute

            	end

               
        end
=end 
     
     puts ">>>>>>>>>>>>>>Number: #{count}"
     count = count + 1
   end
   
end

#func
#get_prev_child_id
