module MigrateMother
	def self.new_mother(person, params,mother_type)
     
	    if MigrateChild.is_twin_or_triplet(params[:person][:type_of_birth])
	      mother_person = Person.find(params[:person][:prev_child_id]).mother
	    else	       
	        if mother_type =="Adoptive-Mother"
	          mother = params[:person][:foster_mother]
	        else
	          mother = params[:person][:mother]
	        end

	        if mother[:first_name].blank?
	          return nil
	        end

	     begin
	        core_person = CorePerson.create(
	            :person_type_id     => PersonType.where(name: mother_type).last.id,
	            :created_at         => params[:person][:created_at].to_date.to_s,
	            :updated_at         => params[:person][:updated_at].to_date.to_s
	        )
	      
	        mother[:citizenship] = 'Malawian' if mother[:citizenship].blank?
	        mother[:residential_country] = 'Malawi' if mother[:residential_country].blank?


	        mother_person = Person.create(
	            :person_id          => core_person.id,
	            :gender             => 'F',
	            :birthdate          => ((mother[:birthdate].to_date.present? rescue false) ? mother[:birthdate].to_date : "1900-01-01"),
	            :birthdate_estimated => ((mother[:birthdate].to_date.present? rescue false) ? 0 : 1),
	            :created_at         => params[:person][:created_at].to_date.to_s,
	            :updated_at         => params[:person][:updated_at].to_date.to_s
	        )

	        person_name = PersonName.create(
	            :person_id          => core_person.id,
	            :first_name         => mother[:first_name],
	            :middle_name        => mother[:middle_name],
	            :last_name          => mother[:last_name],
	            :created_at         => params[:person][:created_at].to_date.to_s,
	            :updated_at         => params[:person][:updated_at].to_date.to_s
	        )
	      
	        cur_district_id         = Location.locate_id_by_tag(mother[:current_district], 'District')
	        cur_ta_id               = Location.locate_id(mother[:current_ta], 'Traditional Authority', cur_district_id)
	        cur_village_id          = Location.locate_id(mother[:current_village], 'Village', cur_ta_id)
	        
	        home_district_id        = Location.locate_id_by_tag(mother[:home_district], 'District')
	        home_ta_id              = Location.locate_id(mother[:home_ta], 'Traditional Authority', home_district_id)
	        home_village_id         = Location.locate_id(mother[:home_village], 'Village', home_ta_id)
	        
	      
	        person_address = PersonAddress.create(
	            :person_id          => core_person.id,
	            :current_district   => cur_district_id,
	            :current_ta         => cur_ta_id,
	            :current_village    => cur_village_id,
	            :home_district   => home_district_id,
	            :home_ta            => home_ta_id,
	            :home_village       => home_village_id,

	            :current_district_other   => mother[:foreigner_home_district],
	            :current_ta_other         => mother[:foreigner_current_ta],
	            :current_village_other    => mother[:foreigner_current_village],
	            :home_district_other      => mother[:foreigner_home_district],
	            :home_ta_other            => mother[:foreigner_home_ta],
	            :home_village_other       => mother[:foreigner_home_village],

	            :citizenship            => Location.where(country: mother[:citizenship]).last.id,
	            :residential_country    => Location.locate_id_by_tag(mother[:residential_country], 'Country'),
	            :address_line_1         => (params[:informant_same_as_mother].present? && params[:informant_same_as_mother] == "Yes" ? params[:person][:informant][:addressline1] : nil),
	            :address_line_2         => (params[:informant_same_as_mother].present? && params[:informant_same_as_mother] == "Yes" ? params[:person][:informant][:addressline2] : nil),
	            :created_at         => params[:person][:created_at].to_date.to_s,
	            :updated_at         => params[:person][:updated_at].to_date.to_s
	        )

	     rescue StandardError => e

	          MigrateChild.log_error(e.message, params)
	     end

	    end

	    unless mother_person.blank?
	      PersonRelationship.create(
	              person_a: person.id, person_b: mother_person.person_id,
	              person_relationship_type_id: PersonRelationType.where(name: mother_type).last.id,
	              created_at: params[:person][:created_at].to_date.to_s,
	              updated_at: params[:person][:updated_at].to_date.to_s
	      )
	    end


	    mother_person
	end



end