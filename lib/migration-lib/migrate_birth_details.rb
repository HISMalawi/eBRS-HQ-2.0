module MigrateBirthDetails
	def self.new_birth_details(person, params)
	    if MigrateChild.is_twin_or_triplet(params[:person][:type_of_birth].to_s)
	      return self.birth_details_multiple(person,params)
	    end
	    person_id = person.id; place_of_birth_id = nil; location_id = nil; other_place_of_birth = nil
	    person = params[:person]

	    if SETTINGS['application_mode'] == 'FC'
	      place_of_birth_id = Location.where(name: 'Hospital').last.id
	      location_id = SETTINGS['location_id']
	    else
	      unless person[:place_of_birth].blank?
	        place_of_birth_id = Location.locate_id_by_tag(person[:place_of_birth], 'Place of Birth')
	      else
	        place_of_birth_id = Location.locate_id_by_tag("Other", 'Place of Birth')
	      end

	      if person[:place_of_birth] == 'Home'
	        district_id = Location.locate_id_by_tag(person[:birth_district], 'District')
	        ta_id = Location.locate_id(person[:birth_ta], 'Traditional Authority', district_id)
	        village_id = Location.locate_id(person[:birth_village], 'Village', ta_id)
	        location_id = [village_id, ta_id, district_id].compact.first #Notice the order

	      elsif person[:place_of_birth] == 'Hospital'
	        map =  {'Mzuzu City' => 'Mzimba',
	                'Lilongwe City' => 'Lilongwe',
	                'Zomba City' => 'Zomba',
	                'Blantyre City' => 'Blantyre'}

	        person[:birth_district] = map[person[:birth_district]] if person[:birth_district].match(/City$/)

	        district_id = Location.locate_id_by_tag(person[:birth_district], 'District')
	        location_id = Location.locate_id(person[:hospital_of_birth], 'Health Facility', district_id)

	        location_id = [location_id, district_id].compact.first

	      else #Other
	        location_id = Location.where(name: 'Other').last.id #Location.locate_id_by_tag(person[:birth_district], 'District')
	        other_place_of_birth = params[:other_birth_place_details]
	      end
	    end

	    reg_type = SETTINGS['application_mode'] =='FC' ? BirthRegistrationType.where(name: 'Normal').first.birth_registration_type_id :
	        BirthRegistrationType.where(name: params[:person][:relationship]).last.birth_registration_type_id
	    

	    unless person[:type_of_birth].blank?

	      if person[:type_of_birth]=='Twin'

	         person[:type_of_birth] ='First Twin'
	      end
	      if person[:type_of_birth]=='Triplet'

	         person[:type_of_birth] ='First Triplet'
	      end

	      type_of_birth_id = PersonTypeOfBirth.where(name: person[:type_of_birth]).last.id

	    else
	      type_of_birth_id = PersonTypeOfBirth.where(name:  'Single').last.id
	    end

	    
	    rel = nil
	    if params[:informant_same_as_mother] == 'Yes'
	      rel = 'Mother'
	    elsif params[:informant_same_as_father] == 'Yes'
	      rel = 'Father'
	    else
	      rel = params[:person][:informant][:relationship_to_person] rescue nil
	    end
	   
	   	level = nil
	  	level = "DC" if params[:district_code].present?
	  	level = "FC" if params[:facility_code].present?

	    details = PersonBirthDetail.create(
	        person_id:                                person_id,
	        birth_registration_type_id:               reg_type,
	        place_of_birth:                           place_of_birth_id,
	        birth_location_id:                        location_id,
	        district_of_birth:                        Location.where("name = '#{params[:person][:birth_district]}' AND code IS NOT NULL").first.id,
	        other_birth_location:                     other_place_of_birth,
	        birth_weight:                             (person[:birth_weight].blank? ? nil : person[:birth_weight]),
	        type_of_birth:                            type_of_birth_id,
	        parents_married_to_each_other:            (person[:parents_married_to_each_other] == 'No' ? 0 : 1),
	        date_of_marriage:                         (person[:date_of_marriage].to_date.to_s rescue nil),
	        gestation_at_birth:                       (params[:gestation_at_birth].blank? ? nil : params[:gestation_at_birth]),
	        number_of_prenatal_visits:                (params[:number_of_prenatal_visits].blank? ? nil : params[:number_of_prenatal_visits]),
	        month_prenatal_care_started:              (params[:month_prenatal_care_started].blank? ? nil : params[:month_prenatal_care_started]),
	        mode_of_delivery_id:                      (ModeOfDelivery.where(name: person[:mode_of_delivery]).first.id rescue 1),
	        number_of_children_born_alive_inclusive:  (params[:number_of_children_born_alive_inclusive].present? ? params[:number_of_children_born_alive_inclusive] : 1),
	        number_of_children_born_still_alive:      (params[:number_of_children_born_still_alive].present? ? params[:number_of_children_born_still_alive] : 1),
	        level_of_education_id:                    (LevelOfEducation.where(name: person[:level_of_education]).last.id rescue 1),
	        court_order_attached:                     (person[:court_order_attached] == 'Yes' ? 1 : 0),
	        parents_signed:                           (person[:parents_signed] == 'Yes' ? 1 : 0),
	        form_signed:                              (person[:form_signed] == 'Yes' ? 1 : 0),
	        informant_designation:                    (params[:person][:informant][:designation].present? ? params[:person][:informant][:designation].to_s : nil),
	        informant_relationship_to_person:          rel,
	        other_informant_relationship_to_person:   (params[:person][:informant][:relationship_to_person].to_s == "Other" ? (params[:person][:informant][:other_informant_relationship_to_person] rescue nil) : nil),
	        acknowledgement_of_receipt_date:          (person[:acknowledgement_of_receipt_date].to_date rescue nil),
	        location_created_at:                      SETTINGS['location_id'],
          source_id:                                params[:_id],
	        date_reported:                            params[:person][:created_at].to_date.to_s,
	        created_at:                               params[:person][:created_at].to_date.to_s,
	        updated_at:                               params[:person][:updated_at].to_date.to_s,
	        level: 									  level
	    )

	    return details

	end

	def self.birth_details_multiple(person,params)
	    
	    prev_details = PersonBirthDetail.where(person_id: params[:person][:prev_child_id].to_s).first
	    
	    begin
	    prev_details_keys = prev_details.attributes.keys
	    exclude_these = ['person_id','person_birth_details_id',"birth_weight","type_of_birth","mode_of_delivery_id","document_id"]
	    prev_details_keys = prev_details_keys - exclude_these

	    details = PersonBirthDetail.new
	    details["person_id"] = person.id
	    details["birth_weight"] = params[:person][:birth_weight]

	    type_of_birth_id = PersonTypeOfBirth.where(name: params[:person][:type_of_birth]).last.id
	    details["type_of_birth"] = type_of_birth_id

	    details["mode_of_delivery_id"] = (ModeOfDelivery.where(name: params[:person][:mode_of_delivery]).first.id rescue 1)

	    prev_details_keys.each do |field|
	        details[field] = prev_details[field]
	    end
	    details.save!

	    rescue StandardError =>e

	      MigrateChild.log_error(e.message,person)

	    end

	    return details
	end
end