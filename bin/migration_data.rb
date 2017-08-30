User.current = User.last

def save_record(params)

    person = PersonService.create_record(params)

      if person.present? 
        record_status = PersonRecordStatus.where(person_id: person.person_id).first
        record_status.update_attributes(status_id: Status.where(name: 'DC-ACTIVE').last.id)
        puts "Record Created ............. "
      end
end

def start
	
	records = Child.all.each

	(records || []).each do |r|

	  data = { person: {duplicate: "", is_exact_duplicate: "", 
		   relationship: r[:relationship], 
		   last_name: r[:last_name], 
		   first_name: r[:first_name], 
		   middle_name: r[:middle_name], 
		   birthdate: r[:birthdate].strftime('%d/%b/%Y'), 
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
		   mother:{
		     last_name: r[:mother][:last_name], 
		     first_name: r[:mother][:first_name], 
		     middle_name: r[:mother][:middle_name] rescue nil, 
		     birthdate: r[:mother][:birthdate].strftime('%d/%b/%Y'), 
		     birthdate_estimated: r[:mother][:birthdate_estimated].strftime('%d/%b/%Y'), 
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
		     birthdate_estimated: r[:father][:birthdate_estimated].strftime('%d/%b/%Y'), 
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
		   copy_mother_name: "No", 
		   controller: "person", 
		   action: "create"
		  }

		 save_record(data)
    end
end

start