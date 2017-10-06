module MigrateFather
  def self.new_father(person, params, father_type)
    if self.is_twin_or_triplet(params[:person][:type_of_birth].to_s)
      father_person = Person.find(params[:person][:prev_child_id]).father
    else
      if father_type =="Adoptive-Father"
        father = params[:person][:foster_father]
      else
        father = params[:person][:father]
      end
      father[:citizenship] = 'Malawian' if father[:citizenship].blank?
      father[:residential_country] = 'Malawi' if father[:residential_country].blank?

      if father[:first_name].blank?
        return nil
      end

     begin

      core_person = CorePerson.create(
          :person_type_id     => PersonType.where(name: father_type).last.id,
          :created_at         => params[:person][:created_at].to_date.to_s,
          :updated_at         => params[:person][:updated_at].to_date.to_s
      )
    
      father_person = Person.create(
          :person_id          => core_person.id,
          :gender             => 'F',
          :birthdate          => (father[:birthdate].blank? ? "1900-01-01" : father[:birthdate].to_date),
          :birthdate_estimated => (father[:birthdate].blank? ? 1 : 0),
          :created_at         => params[:person][:created_at].to_date.to_s,
          :updated_at         => params[:person][:updated_at].to_date.to_s
      )

      PersonName.create(
          :person_id          => core_person.id,
          :first_name         => father[:first_name],
          :middle_name        => father[:middle_name],
          :last_name          => father[:last_name],
          :created_at         => params[:person][:created_at].to_date.to_s,
          :updated_at         => params[:person][:updated_at].to_date.to_s
      )

      cur_district_id         = Location.locate_id_by_tag(father[:current_district], 'District')
      cur_ta_id               = Location.locate_id(father[:current_ta], 'Traditional Authority', cur_district_id)
      cur_village_id          = Location.locate_id(father[:current_village], 'Village', cur_ta_id)

      home_district_id        = Location.locate_id_by_tag(father[:home_district], 'District')
      home_ta_id              = Location.locate_id(father[:home_ta], 'Traditional Authority', home_district_id)
      home_village_id         = Location.locate_id(father[:home_village], 'Village', home_ta_id)
    
     
      PersonAddress.create(
          :person_id          => core_person.id,
          :current_district   => cur_district_id,
          :current_ta         => cur_ta_id,
          :current_village    => cur_village_id,
          :home_district   => home_district_id,
          :home_ta            => home_ta_id,
          :home_village       => home_village_id,

          :current_district_other   => father[:foreigner_home_district],
          :current_ta_other         => father[:foreigner_current_ta],
          :current_village_other    => father[:foreigner_current_village],
          :home_district_other      => father[:foreigner_home_district],
          :home_ta_other            => father[:foreigner_home_ta],
          :home_village_other       => father[:foreigner_home_village],

          :citizenship            => Location.where(country: father[:citizenship]).last.id,
          :residential_country    => Location.locate_id_by_tag(father[:residential_country], 'Country'),
          :address_line_1         => (params[:informant_same_as_father].present? && params[:informant_same_as_father] == "Yes" ? params[:person][:informant][:addressline1] : nil),
          :address_line_2         => (params[:informant_same_as_father].present? && params[:informant_same_as_father] == "Yes" ? params[:person][:informant][:addressline2] : nil),
          :created_at         => params[:person][:created_at].to_date.to_s,
          :updated_at         => params[:person][:updated_at].to_date.to_s
      )
     rescue StandardError => e

          self.log_error(e.message, params)
     end
    end

    unless father_person.blank?
      PersonRelationship.create(
              person_a: person.id, person_b: father_person.person_id,
              person_relationship_type_id: PersonRelationType.where(name: father_type).last.id,
              created_at: params[:person][:created_at].to_date.to_s,
              updated_at: params[:person][:updated_at].to_date.to_s
      )
    end
    

    father_person

  end
end