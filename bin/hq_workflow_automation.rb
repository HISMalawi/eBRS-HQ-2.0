status_id = Status.where(name: "HQ-ACTIVE").first.id

person_ids = PersonRecordStatus.find_by_sql("
	 SELECT d.person_id FROM person_birth_details d
	INNER JOIN person_record_statuses prs ON d.person_id = prs.person_id
	WHERE prs.status_id = #{status_id} AND prs.voided = 0
	 ").map(&:person_id).uniq

puts person_ids.count
#raise '######'.to_s
user = User.where(username: "admin279").first.id

#raise user.inspect

person_ids.each_with_index do |person_id, i|

	active_statuses = PersonRecordStatus.where(person_id: person_id, voided: 0).count
	active_statuses = active_statuses.to_i
        
	next if active_statuses > 1

        #raise active_statuses.inspect

	child = PersonBirthDetail.where(person_id: person_id).first
	child_id = child.person_id rescue nil
		
	father = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 1).first
	father_id = father.person_b rescue nil

	adoptive_father = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 3).first
	adoptive_father_id = father.person_b rescue nil

	mother = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 5).first
	mother_id = mother.person_b rescue nil

	adoptive_mother = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 2).first
	adoptive_mother_id = mother.person_b rescue nil

	informant = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 4).first
	informant_id = informant.person_b rescue nil

#### CHILD MANDATORY FIELDS ##############

	detail = PersonBirthDetail.where(person_id: person_id).first
	ben = detail.district_id_number rescue nil
	place_of_birth = detail.place_of_birth rescue nil
	date_reported = detail.acknowledgement_of_receipt_date rescue nil
	
	person_names = PersonName.where(person_id: person_id).first
	child_first_name = person_names.first_name rescue nil
	child_last_name = person_names.last_name rescue nil

	person = Person.where(person_id: person_id).first
	birth_date = person.birthdate rescue nil
	sex = person.gender rescue nil

	current_date = Date.today
	child_age = (current_date - birth_date)/365

	nid_identifier = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: 4).first
	national_id = nid_identifier.value rescue nil

#### MOTHER MANDATORY FIELDS ##########
	mother_names = PersonName.where(person_id: mother_id).first
	mother_first_name = mother_names.first_name rescue nil
	mother_last_name = mother_names.last_name rescue nil

	address = PersonAddress.where(person_id: mother_id).first
	mother_nationality = address.citizenship rescue nil

########## FATHER NAMES ########################
	father_names = PersonName.where(person_id: father_id).first
	father_address = PersonAddress.where(person_id: father_id).first
	first_name_father =father_names.first_name rescue nil
	last_name_father = father_names.last_name rescue nil

############# BUILD DUPLICATE QUERY STRING

	def format_person(person_id)
		person_names = PersonName.where(person_id: person_id).first 
		p = Person.where(person_id: person_id).first

		mother = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 5).first
		mother_id = mother.person_b rescue nil
		mother_names = PersonName.where(person_id: mother_id).first

		father = PersonRelationship.where(person_a: person_id, person_relationship_type_id: 1).first
		father_id = father.person_b rescue nil
		father_names = PersonName.where(person_id: father_id).first

		address = PersonAddress.where(person_id: mother_id).first
		father_address = PersonAddress.where(person_id: father_id).first

		detail = PersonBirthDetail.where(person_id: person_id).first

		person = {}
		person["id"] = person_id
		person["first_name"]= person_names.first_name rescue ''
		person["last_name"] =  person_names.last_name rescue ''
		person["middle_name"] = person_names.middle_name rescue ''
		person["gender"] = p.gender rescue ''
		person["birthdate"]= p.birthdate rescue ''
		person["birthdate_estimated"] = 0
		person["nationality"]=  mother_nationality rescue ''
		person["place_of_birth"] = Location.find(detail.place_of_birth).name rescue '' 
		person["district"] = Location.find(detail.district_of_birth).name rescue ''
		person["mother_first_name"]= mother_names.first_name rescue ''
		person["mother_last_name"] =  mother_names.last_name rescue ''
		person["mother_middle_name"] = mother_names.middle_name rescue ''

		person["mother_home_district"] = Location.find(address.home_district).name  rescue ''
		person["mother_home_ta"] = Location.find(address.home_ta).name rescue ''
		person["mother_home_village"] = Location.find(address.home_village).name rescue ''

		person["mother_current_district"] = ''
		person["mother_current_ta"] = ''
		person["mother_current_village"] = ''

		person["father_first_name"]= father_names.first_name rescue ''
		person["father_last_name"] =  father_names.last_name rescue ''
		person["father_middle_name"] = father_names.middle_name rescue ''

		person["father_home_district"] = Location.find(father_address.home_district).name rescue ''
		person["father_home_ta"] = Location.find(father_address.home_ta).name rescue ''
		person["father_home_village"] = Location.find(father_address.home_village).name rescue ''

		person["father_current_district"] = ''
		person["father_current_ta"] = ''
		person["father_current_village"] = ''
		person
	end


###################### BEGIN COMPLETENESS CHECK ####################

	if child.blank? 
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child details')
		new_status.save

		puts "#{child_id}: Missing Child Name"

	elsif ben.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing Birth Entry Number')
		new_status.save

		puts "#{child_id}: Missing BEN"

	elsif child_first_name.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child first name')
		new_status.save

		puts "#{child_id}: Missing child first name"

	elsif child_last_name.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child last name')
		new_status.save

		puts "#{child_id}: Missing child last name"

	elsif birth_date.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child date of birth')
		new_status.save

		puts "#{child_id}: Missing child date of birth"

	elsif detail.district_of_birth.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child district of birth')
		new_status.save

		puts "#{child_id}: Missing child district of birth"

	elsif sex.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing child gender')
		new_status.save

		puts "#{child_id}: Missing Child Gender"

	elsif place_of_birth.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing place of birth')
		new_status.save

		puts "#{child_id}: Missing place of birth"

	elsif mother.blank? && adoptive_mother.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing mother details')
		new_status.save

		puts "#{child_id}: Missing mother details"

	elsif mother_nationality.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing mother nationality')
		new_status.save

		puts "#{child_id}: Missing mother nationality"

	elsif mother_first_name.blank? || mother_last_name.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing mother names')
		new_status.save

		puts "#{child_id}: Missing mother names"

	
		

	elsif informant.blank?
		new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
		prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
		prs.voided = 1
		prs.save

		new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing informant details')
		new_status.save

		puts "#{child_id}: Missing informant details"

	else

		if detail.parents_married_to_each_other == 1 || detail.court_order_attached == 1 || detail.parents_signed == 1
			if first_name_father.blank? || last_name_father.blank?
				new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
				prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
				prs.voided = 1
				prs.save

				new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing father names')
				new_status.save

				puts "#{child_id}: Missing father names"

			elsif father_address.citizenship.blank?
				new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
				prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
				prs.voided = 1
				prs.save

				new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing father nationality')
				new_status.save

				puts "#{child_id}: Missing father nationality"
			end
			next if first_name_father.blank?
			next if last_name_father.blank?
			next if father_address.citizenship.blank?
		end

####### End of completeness Check ###################################

##### BEGIN DUPLICATE CHECK ##################

		duplicate_query_string = format_person(person_id)

		birth_type = PersonBirthDetail.where(person_id: person_id).first
		@results = []

        duplicates = SimpleElasticSearch.query_duplicate_coded(duplicate_query_string,SETTINGS['duplicate_precision'])
        duplicates.delete_if{|e| e["_id"].to_i == person_id.to_i}
        duplicates.each do |dup|

              #Only catch for against records with BEN or Record is still at DRO although available in HQ application
              next if PersonBirthDetail.where(" person_id = #{dup['_id']} AND district_id_number IS NULL ").present?
              @results << dup
        end

        if @results.present? && birth_type.type_of_birth == 1
           potential_duplicate = PotentialDuplicate.create(person_id: person_id,created_at: (Time.now))
           if potential_duplicate.present?
                 @results.each do |result|
                    potential_duplicate.create_duplicate(result["_id"])
                 end
           end

           new_status_id = Status.where(name: "HQ-POTENTIAL DUPLICATE").first.id
			prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
			prs.voided = 1
			prs.save

			new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Marked Duplicate by autocheck')
			new_status.save

			puts "#{child_id}: Marked Duplicate"

        end

        next if @results.present?
		
######### END DUPLICATE CHECK ########

		if child_age >= 16
			if national_id.blank?
				new_status_id = Status.where(name: "HQ-REJECTED").first.id
				prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
				prs.voided = 1
				prs.save

				new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Missing national ID')
				new_status.save

				puts "#{child_id}: Missing National ID"

			else
				#raise national_id.inspect
				puts validate = NIDValidator.validate(person, national_id)

				if validate.blank?
					new_status_id = Status.where(name: "HQ-REJECTED").first.id
					prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
					prs.voided = 1
					prs.save

					new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Could not validate National ID')
					new_status.save

					puts "#{child_id}: Could not validate National ID"

				else
					validate = NIDValidator.validate(person, national_id)
#### IF ANY OF THESE FIELDS IS RETURNED THEN THERE IS A MISMATCH #############################################
					nid_first_name 			= (validate["FirstName"][:remote]) rescue nil
					nid_last_name 			= (validate["Surname"][:remote]) rescue nil
					nid_gender 				= (validate["Sex"][:remote]) rescue nil
					nid_dob 				= (validate["DateOfBirthString"][:remote]) rescue nil
					nid_birth_district 		= (validate["PlaceOfBirthDistrictName"][:remote]) rescue nil

					nid_mother_first_name	= (validate["MotherFirstName"][:remote]) rescue nil
					nid_mother_last_name	= (validate["MotherSurname"][:remote]) rescue nil
					nid_mother_district		= (validate["MotherDistrictName"][:remote]) rescue nil
					nid_mother_nationality	= (validate["MotherNationality"][:remote]) rescue nil

					nid_father_first_name	= (validate["FatherFirstName"][:remote]) rescue nil
					nid_father_last_name	= (validate["FatherSurname"][:remote]) rescue nil
					nid_father_nationality	= (validate["FatherNationality"][:remote]) rescue nil


					if nid_first_name.present? || nid_last_name.present? || nid_gender.present? ||  nid_dob.present? || nid_birth_district.present? || nid_mother_first_name.present? || nid_mother_last_name.present? || nid_mother_district.present? || nid_mother_nationality.present? || nid_father_first_name.present? || nid_father_last_name.present? || nid_father_nationality.present?
						
						new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
						prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
						prs.voided = 1
						prs.save

						new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Check mismatching details with NRIS')
						new_status.save

					else
						puts "generating brn"
						## QUERRY BRN ##
						d = PersonBirthDetail.where(person_id: person_id).first
						brn = d.generate_brn
						d.save

						new_status_id = Status.where(name: "HQ-CAN-PRINT").first.id
						prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
						prs.voided = 1
						prs.save

						new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Pushed to CAN PRINT by autocheck after validating NID')
						new_status.save

						puts "#{child_id}: pushed to CAN PRINT after validating NID"
					end #end nid validation
				end #end validate

			end #end national_id check

		else
			puts "generating brn"
			## QUERRY BRN ##
			d = PersonBirthDetail.where(person_id: person_id).first
			brn = d.generate_brn
			d.save

####		#### QUERRY NATIONAL ID ####

			nid_req = PersonService.request_nris_id(person_id, "N/A", user) rescue nil
 			nid_identifier = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: 4).first
 			new_nid = nid_identifier.value rescue nil

 			if new_nid.present?
 				nid_identifier.save
 			end #end new_id

			if nid_req.present?
				new_status_id = Status.where(name: "HQ-CAN-PRINT").first.id
				prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
				prs.voided = 1
				prs.save

				new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Pushed to CAN PRINT after generating NID')
				new_status.save

				puts "#{child_id}:  ## #{new_nid} pushed to CAN PRINT by autocheck"


			else
				new_status_id = Status.where(name: "HQ-INCOMPLETE").first.id
				prs = PersonRecordStatus.where(person_id: person_id, status_id: status_id).order('created_at asc').last
				prs.voided = 1
				prs.save

				new_status = PersonRecordStatus.new(status_id: new_status_id, person_id: person_id, creator: user, voided: 0, void_reason: nil, voided_by: nil, date_voided: nil, comments: 'Could not generate National ID')
				new_status.save				
			end #end nid_req
			
		end #end child_age check
			
	end

end #end loop
