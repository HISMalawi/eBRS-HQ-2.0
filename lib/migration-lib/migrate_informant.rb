module MigrateInformant
	def self.new_informant(person, params)

	    informant_person = nil; core_person = nil

	    informant = params[:person][:informant]
	    informant[:citizenship] = 'Malawian' if informant[:citizenship].blank?
	    informant[:residential_country] = 'Malawi' if informant[:residential_country].blank?

	    if MigrateChild.is_twin_or_triplet(params[:person][:type_of_birth].to_s)
	      informant_person = Person.find(params[:person][:prev_child_id]).informant
	    elsif params[:informant_same_as_mother] == 'Yes'

	      if params[:person][:relationship] == "adopted"
	          informant_person = person.adoptive_mother
	      else
	         informant_person = person.mother
	      end
	    elsif params[:informant_same_as_father] == 'Yes'
	      if params[:person][:relationship] == "adopted"
	          informant_person = person.adoptive_father
	      else
	         informant_person = person.father
	      end
	    else
	    
	    
	      core_person = CorePerson.create(
	          :person_type_id => PersonType.where(:name => 'Informant').last.id,
	          :created_at     => params[:person][:created_at].to_date.to_s,
	          :updated_at     => params[:person][:updated_at].to_date.to_s
	      )

	      informant_person = Person.create(
	          :person_id          => core_person.id,
	          :gender             => "N/A",
	          :birthdate          => (informant[:birthdate].blank? ? "1900-01-01" : informant[:birthdate].to_date),
	          :birthdate_estimated => (informant[:birthdate].blank? ? 1 : 0),
	          :created_at         => params[:person][:created_at].to_date.to_s,
	          :updated_at         => params[:person][:updated_at].to_date.to_s
	      )

	      PersonName.create(
	          :person_id   => informant_person.id,
	          :first_name  => informant[:first_name],
	          :middle_name => informant[:middle_name],
	          :last_name   => informant[:last_name],
	          :created_at  => params[:person][:created_at].to_date.to_s,
	          :updated_at  => params[:person][:updated_at].to_date.to_s
	      )

	      cur_district_id         = Location.locate_id_by_tag(informant[:current_district], 'District')
	      cur_ta_id               = Location.locate_id(informant[:current_ta], 'Traditional Authority', cur_district_id)
	      cur_village_id          = Location.locate_id(informant[:current_village], 'Village', cur_ta_id)

	      home_district_id        = Location.locate_id_by_tag(informant[:home_district], 'District')
	      home_ta_id              = Location.locate_id(informant[:home_ta], 'Traditional Authority', home_district_id)
	      home_village_id         = Location.locate_id(informant[:home_village], 'Village', home_ta_id)
	     
	      PersonAddress.create(
	          :person_id          => core_person.id,
	          :current_district   => cur_district_id,
	          :current_ta         => cur_ta_id,
	          :current_village    => cur_village_id,
	          :home_district   => home_district_id,
	          :home_ta            => home_ta_id,
	          :home_village       => home_village_id,
	          :citizenship            => Location.where(country: informant[:citizenship]).last.id,
	          :residential_country    => Location.locate_id_by_tag(informant[:residential_country], 'Country'),
	          :address_line_1         => informant[:addressline1],
	          :address_line_2         => informant[:addressline2],
	          :created_at         => params[:person][:created_at].to_date.to_s,
	          :updated_at         => params[:person][:updated_at].to_date.to_s
	      )
	  

	    end

	    PersonRelationship.create(
	        person_a: person.id, person_b: informant_person.id,
	        person_relationship_type_id: PersonRelationType.where(name: 'Informant').last.id,
	        created_at: params[:person][:created_at].to_date.to_s,
	        updated_at: params[:person][:updated_at].to_date.to_s
	    )


	    if informant[:phone_number].present?
	      PersonAttribute.create(
	          :person_id                => informant_person.id,
	          :person_attribute_type_id => PersonAttributeType.where(name: 'cell phone number').last.id,
	          :value                    => informant[:phone_number],
	          :voided                   => 0,
	          :created_at               => params[:person][:created_at].to_date.to_s,
	          :updated_at               => params[:person][:updated_at].to_date.to_s
	      )
	    end

	    informant_person
	end
end