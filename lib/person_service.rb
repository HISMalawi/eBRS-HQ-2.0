module PersonService
  require 'bean'
  require 'json'

  def self.create_record(params)


    adoption_court_order              = params[:person][:adoption_court_order] rescue nil
    desig              = params[:person][:informant][:designation] rescue nil
    birth_place_details_available     = params[:birth_place_details_available]
    parents_details_available         = params[:parents_details_available]
    biological_parents                = params[:biological_parents]
    foster_parents                    = params[:foster_parents]

    first_name                        = params[:person][:first_name]
    last_name                         = params[:person][:last_name]

    #raise last_name.inspect

    middle_name                       = params[:person][:middle_name]
    birthdate                         = params[:birthdate]
    place_of_birth                    = params[:person][:place_of_birth]
    hospital_of_birth                 = params[:person][:hospital_of_birth]
    birth_district                    = params[:person][:birth_district]
    birth_weight                      = params[:person][:birth_weight]
    acknowledgement_of_receipt_date   = params[:person][:acknowledgement_of_receipt_date]

    gender                            = params[:person][:gender]
    home_address_same_as_physical     = params[:person][:home_address_same_as_physical]
    same_address_with_mother          = params[:person][:same_address_with_mother]
    registration_type                 = params[:person][:registration_type]
    copy_mother_name                  = params[:person][:copy_mother_name]
    type_of_birth                     = params[:person][:type_of_birth]

    #raise birthdate.inspect

    ################################ mother details ###############################################

      mother_last_name                  = params[:person][:mother][:last_name]
      mother_first_name                 = params[:person][:mother][:first_name]
      mother_middle_name                = params[:person][:mother][:middle_name]
      mother_birthdate                  = params[:person][:mother][:birthdate]
      mother_citizenship                = params[:person][:mother][:citizenship]
      mother_residental_country         = params[:person][:mother][:residential_country]
      mother_foreigner_current_district = params[:person][:mother][:foreigner_current_district]
      mother_foreigner_current_village  = params[:person][:mother][:foreigner_current_village]
      mother_foreigner_current_ta       = params[:person][:mother][:foreigner_current_ta]
      mother_home_country               = params[:person][:mother][:home_country]
      mother_foreigner_home_district    = params[:person][:mother][:foreigner_home_district]
      mother_foreigner_home_village     = params[:person][:mother][:foreigner_home_village]
      mother_foreigner_home_ta          = params[:person][:mother][:foreigner_home_ta]
      mother_estimated_dob              = params[:person][:mother][:birthdate_estimated]
      mother_current_district           = params[:person][:mother][:current_district]
      mother_current_ta                 = params[:person][:mother][:current_ta]
      mother_current_village            = params[:person][:mother][:current_village]

      mother_mode_of_delivery           = params[:person][:mode_of_delivery]
      mother_level_of_education         = params[:person][:level_of_education]

    ################################ mother details (end) #######################################

    ########################### father details ########################################


      informant_same_as_mother          = params[:informant_same_as_mother]
      informant_same_as_father          = params[:informant_same_as_father]

      father_birthdate_estimated        = params[:person][:father][:birthdate_estimated]
      father_residential_country        = params[:person][:father][:residential_country]
      father_foreigner_current_district = params[:person][:father][:foreigner_current_district]
      father_foreigner_current_village  = params[:person][:father][:foreigner_current_village]
      father_foreigner_current_ta       = params[:person][:father][:foreigner_current_ta]
      father_residental_country         = params[:person][:father][:residential_country]
      father_foreigner_home_village     = params[:person][:father][:foreigner_home_village]
      father_foreigner_home_ta          = params[:person][:father][:foreigner_home_ta]
      father_last_name                   = params[:person][:father][:last_name]
      father_first_name                  = params[:person][:father][:first_name]
      father_middlename                 = params[:person][:father][:middle_name]
      father_birthdate                  = params[:person][:father][:birthdate]
      father_citizenship                = params[:person][:father][:citizenship]
      father_current_district           = params[:person][:father][:current_district]
      father_current_ta                 = params[:person][:father][:current_ta]
      father_current_village            = params[:person][:father][:current_village]
      father_home_district              = params[:person][:father][:home_district]
      father_home_ta                    = params[:person][:father][:home_ta]
      father_home_village               = params[:person][:father][:home_village]



    ######################### father details (end) #################################


    informant_last_name               = params[:person][:informant][:last_name]
    informant_first_name              = params[:person][:informant][:first_name]
    informant_middle_name             = params[:person][:informant][:middle_name]
    informant_relationship_to_child   = params[:person][:informant][:relationship_to_child]
    informant_current_district        = params[:person][:informant][:current_district]
    informant_current_ta              = params[:person][:informant][:current_ta]
    informant_current_village         = params[:person][:informant][:current_village]
    informant_addressline1            = params[:person][:informant][:addressline1]
    informant_addressline2            = params[:person][:informant][:addressline2]
    informant_phone_number            = params[:person][:informant][:phone_number]

    informant_form_signed             = params[:person][:form_signed]



     #raise informant_current_ta.inspect

    court_order_attached              = params[:person][:court_order_attached]
    parents_signed                    = params[:person][:parents_signed]

    parents_married_to_each_other     = params[:person][:parents_married_to_each_other]

    month_prenatal_care_started               = params[:month_prenatal_care_started]
    number_of_prenatal_visits                 = params[:number_of_prenatal_visits]
    gestation_at_birth                        = params[:gestation_at_birth]
    number_of_children_born_alive_inclusive   = params[:number_of_children_born_alive_inclusive].to_i rescue 1
    number_of_children_born_still_alive       = params[:number_of_children_born_still_alive].to_i rescue 1
    details_of_father_known                   = params[:details_of_father_known]

    ################################ Is record a duplicate ##########################################################
    is_record_a_duplicate = params[:person][:duplicate] rescue nil
  ################################################## Recording client details #####################################

 if SETTINGS["application_mode"] == "FC"


    core_person = CorePerson.create(person_type_id: PersonType.where(name: 'Client').first.id)

    @person = Person.create(person_id: core_person.id,
      gender: gender.first,
      birthdate: (birthdate.to_date rescue Date.today))

    person_name = PersonName.create(first_name: first_name,
      middle_name: middle_name,
      last_name: last_name, person_id: core_person.id)

    PersonNameCode.create(person_name_id: person_name.id,
      first_name_code: first_name.soundex,
      last_name_code: last_name.soundex,
      middle_name_code: (middle_name.soundex rescue nil))




    PersonBirthDetail.create(
      person_id:                                core_person.id,
      birth_registration_type_id:               SETTINGS['application_mode'] =='FC' ? BirthRegistrationType.where(name: 'Normal').first.birth_registration_type_id : BirthRegistrationType.where(name: params[:registration_type]).first.birth_registration_type_id,
      place_of_birth:                           Location.where(location_id: SETTINGS['location_id']).first.location_id,
      birth_location_id:                        Location.where(location_id: SETTINGS['location_id']).first.location_id,
      birth_weight:                             birth_weight,
      type_of_birth:                            self.is_num?(type_of_birth) == true ? PersonTypeOfBirth.where(person_type_of_birth_id: type_of_birth).first.id : PersonTypeOfBirth.where(name: type_of_birth).first.id,
      parents_married_to_each_other:            (parents_married_to_each_other == 'No' ? 0 : 1),
      date_of_marriage:                         (date_of_marriage.to_date rescue nil),
      gestation_at_birth:                       (gestation_at_birth.to_f rescue nil),
      number_of_prenatal_visits:                (number_of_prenatal_visits.to_i rescue nil),
      month_prenatal_care_started:              (month_prenatal_care_started.to_i rescue nil),
      mode_of_delivery_id:                      (ModeOfDelivery.where(name: mother_mode_of_delivery).first.id rescue 1),
      number_of_children_born_alive_inclusive:  (number_of_children_born_alive_inclusive),
      number_of_children_born_still_alive:      (number_of_children_born_still_alive),
      level_of_education_id:                    (LevelOfEducation.where(name: mother_level_of_education).first.id rescue 1),
      district_id_number:                       nil,
      national_serial_number:                   nil,
      court_order_attached:                     (court_order_attached == 'No' ? 0 : 1),
      acknowledgement_of_receipt_date:          (acknowledgement_of_receipt_date.to_date rescue nil),
      facility_serial_number:                   nil,
      adoption_court_order:                     0,

    )



############################################## Client details end ####################################################


############################################# recording mother details ##############################################

 if !mother_first_name.blank?


 core_person_mother = CorePerson.create(person_type_id: PersonType.where(name: 'Mother').first.id)

       person_mother = Person.create(person_id: core_person_mother.id,
                    gender: "F",
                    birthdate: (mother_birthdate.to_date rescue "1900-01-01".to_date))

       person_name_mother = PersonName.create(first_name: mother_first_name,
                    middle_name: mother_middle_name,
                    last_name: mother_last_name, person_id: core_person_mother.id)

       PersonNameCode.create(person_name_id: person_name_mother.id,
                    first_name_code: mother_first_name.soundex,
                    last_name_code: mother_last_name.soundex,
                    middle_name_code: (mother_middle_name.soundex rescue nil))

       PersonRelationship.create(person_a: core_person.id, person_b: core_person_mother.id,
                    person_relationship_type_id: PersonRelationType.where(name: 'Mother').first.id)


       PersonAddress.create(person_id: core_person_mother.id,
                    current_village: Location.where(name: mother_current_village).first.location_id,
                    current_village_other: "",
                    current_ta: Location.where(name: mother_current_ta).first.location_id,
                    current_ta_other: "",
                    current_district: Location.where(name: mother_current_district).first.location_id,
                    current_district_other: "",
                    home_village: Location.where(name: mother_home_village).first.location_id,
                    home_village_other: "",
                    home_ta: Location.where(name: mother_home_ta).first.location_id,
                    home_ta_other: "",
                    home_district: Location.where(name: mother_current_district).first.location_id,
                    home_district_other: "",
                    citizenship: Location.where(name: mother_residental_country).first.location_id,
                    residential_country: Location.where(name: mother_residental_country).first.location_id) rescue nil



end
#############################################################################################################################


########################################## Recording father details #################################################
    if !father_first_name.blank?



      core_person_father = CorePerson.create(person_type_id: PersonType.where(name: 'Father').first.id)
            #raise .inspect
            if father_birthdate.blank?
              father_birthdate = "1900-01-01".to_date
            end
            #raise father_birthdate.to_time.to_s.split(" ")[0].inspect
            person_father = Person.create(person_id: core_person_father.id,
                gender: "M",
                birthdate: (father_birthdate.to_date rescue "1900-01-01".to_date))

            person_name_father = PersonName.create(first_name: father_first_name,
                middle_name: (father_middlename rescue nil),
                last_name: father_last_name, person_id: core_person_father.id)

            PersonNameCode.create(person_name_id: person_name_father.id,
                first_name_code: father_first_name.soundex,
                last_name_code: father_last_name.soundex,
                middle_name_code: (father_middlename.soundex rescue nil))

            PersonRelationship.create(person_a: core_person.id, person_b: core_person_father.id,
                person_relationship_type_id: PersonRelationType.where(name: 'Father').first.id)




            father_address_record = PersonAddress.new(person_id: core_person_father.id,
                                 current_village: father_current_village == '' ? '' : Location.where(name: father_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: father_current_ta == '' ? '' : Location.where(name: father_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: father_current_district == '' ? '' : Location.where(name: father_current_district).first.location_id,
                                 current_district_other: "",
                                 home_village: father_home_village == '' ? '' : Location.where(name: father_home_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: father_home_ta == '' ? '' : Location.where(name: father_home_ta).first.location_id,
                                 home_ta_other: "",
                                 home_district: father_current_district == '' ? '' : Location.where(name: father_current_district).first.location_id,
                                 home_district_other: "",
                                 citizenship: father_residental_country == '' ? '' : Location.where(name: father_residental_country).first.location_id,
                                 residential_country: father_residental_country == '' ? '' : Location.where(name: father_residental_country).first.location_id) rescue nil

           father_address_record.save

    end
   ############################################# father details end ###########################################################

   ######################################### Recording informant details #############################################

    if (informant_same_as_mother == "Yes")



              PersonRelationship.create(person_a: core_person.id, person_b: core_person_mother.id,
              person_relationship_type_id: PersonRelationType.where(name: 'Informant').first.id)
              informant_id = core_person_mother.id

  ## here in this block of code, the assumption is that the address details for the mother have been saved since the
  ## mother is the same as the informant, hence commenting the below code
=begin
      PersonAddress.create(person_id: core_person_mother.id,
                                 current_village: mother_current_village == '' ? '' : Location.where(name: mother_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: mother_current_ta == '' ? '' : Location.where(name: mother_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: mother_current_district == '' ? '' : Location.find_by_name(mother_current_district).location_id,
                                 current_district_other: "",
                                 home_village: mother_current_village == '' ? '' : Location.where(name:mother_current_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: mother_current_ta == '' ? '' : Location.where(name:mother_current_ta).first.location_id,
                                 citizenship: mother_residental_country == '' ? '' : Location.where(name: mother_residental_country).first.location_id,
                                 residential_country: mother_residental_country == '' ? '' : Location.where(name: mother_residental_country).first.location_id,
                                 address_line_1: informant_addressline1,
                                 address_line_2: informant_addressline2)
=end

    elsif (informant_same_as_father == "Yes")



              PersonRelationship.create(person_a: core_person.id, person_b: core_person_father.id,
              person_relationship_type_id: PersonRelationType.where(name: 'Informant').first.id)
              informant_id = core_person_father.id

   ## here in this block of code, the assumption is that the address details for the father have been saved since the
   ## father is the same as the informant, hence commenting the below code
=begin
          PersonAddress.create(person_id: core_person_father.id,
                                 current_village: Location.where(name: father_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: Location.where(name: father_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: Location.find_by_name(father_current_district).location_id,
                                 current_district_other: "",
                                 home_village: Location.where(name:father_current_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: Location.where(name:father_current_ta).first.location_id,
                                 citizenship: Location.where(name: 'Malawi').first.location_id,
                                 residential_country: Location.where(name: 'Malawi').first.location_id,
                                 address_line_1: informant_addressline1,
                                 address_line_2: informant_addressline2)
=end

   elsif !informant_first_name.blank?



            core_person_informant = CorePerson.create(person_type_id: PersonType.where(name: 'Informant').first.id)
            informant_id = core_person_informant.id
            person_informant = Person.create(person_id: core_person_informant.id,
                gender: "N/A",
                birthdate: ("1900-01-01".to_date))

            #raise informant_first_name.inspect

            person_name_informant = PersonName.create(first_name: informant_first_name,
                middle_name: (informant_middle_name rescue nil),
                last_name: informant_last_name, person_id: core_person_informant.id)
            begin

              PersonNameCode.create(person_name_id: person_name_informant.id,
                first_name_code: informant_first_name.soundex,
                last_name_code: informant_last_name.soundex,
                middle_name_code: (informant_middle_name.soundex rescue nil))
            rescue

            end

            PersonRelationship.create(person_a: core_person.id, person_b: core_person_informant.id,
                person_relationship_type_id: PersonType.where(name: 'Informant').first.id)

            PersonAddress.create(person_id: core_person_informant.id,
                                 current_village: informant_current_village == '' ? '' : Location.where(name: informant_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: informant_current_ta == '' ? '' : Location.where(name: informant_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: informant_current_district == '' ? '' : Location.find_by_name(informant_current_district).location_id,
                                 current_district_other: "",
                                 home_village: informant_current_village == '' ? '' : Location.where(name:informant_current_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: informant_current_ta == '' ? '' : Location.where(name:informant_current_ta).first.location_id,
                                 citizenship: Location.where(name: 'Malawi').first.location_id,
                                 residential_country: Location.where(name: 'Malawi').first.location_id,
                                 address_line_1: informant_addressline1,
                                 address_line_2: informant_addressline2)

   end

   ############################################## Informant details end #############################################

   ############################################### Person record Status ###############################################

   PersonRecordStatus.new_record_state(core_person.id, 'DC-COMPLETE')

   ####################################################################################################################

elsif SETTINGS["application_mode"] == "DC"

   #raise params[:person][:mother][:current_district].inspect
   #raise mother_current_district.inspect

  ################################################### Client details ############################################

    core_person = CorePerson.create(person_type_id: PersonType.where(name: 'Client').first.id)

    @person = Person.create(person_id: core_person.id,
      gender: gender.first,
      birthdate: (birthdate.to_date rescue Date.today))

    person_name = PersonName.create(first_name: first_name,
      middle_name: middle_name,
      last_name: last_name, person_id: core_person.id)

    PersonNameCode.create(person_name_id: person_name.id,
      first_name_code: first_name.soundex,
      last_name_code: last_name.soundex,
      middle_name_code: (middle_name.soundex rescue nil))



    if hospital_of_birth.blank?

       birth_location_id = self.is_num?(place_of_birth) == true ? place_of_birth : Location.where(name: place_of_birth).first.location_id

    else

      birth_location_id = Location.where(name: hospital_of_birth).first.location_id

    end


    PersonBirthDetail.create(
      person_id:                                core_person.id,
      birth_registration_type_id:               BirthRegistrationType.where(name: params[:relationship]).first.birth_registration_type_id,
      place_of_birth:                           self.is_num?(place_of_birth) == true ? place_of_birth : Location.where(name: place_of_birth).first.location_id,
      birth_location_id:                        birth_location_id,
      birth_weight:                             birth_weight,
      type_of_birth:                            self.is_num?(type_of_birth) == true ? PersonTypeOfBirth.where(person_type_of_birth_id: type_of_birth).first.id : PersonTypeOfBirth.where(name: type_of_birth).first.id,
      parents_married_to_each_other:            (parents_married_to_each_other == 'No' ? 0 : 1),
      date_of_marriage:                         (date_of_marriage.to_date rescue nil),
      gestation_at_birth:                       (gestation_at_birth.to_f rescue nil),
      number_of_prenatal_visits:                (number_of_prenatal_visits.to_i rescue nil),
      month_prenatal_care_started:              (month_prenatal_care_started.to_i rescue nil),
      mode_of_delivery_id:                      (ModeOfDelivery.where(name: mother_mode_of_delivery).first.id rescue 1),
      number_of_children_born_alive_inclusive:  (number_of_children_born_alive_inclusive),
      number_of_children_born_still_alive:      (number_of_children_born_still_alive),
      level_of_education_id:                    (LevelOfEducation.where(name: mother_level_of_education).first.id rescue 1),
      district_id_number:                       nil,
      national_serial_number:                   nil,
      court_order_attached:                     (court_order_attached == 'No' ? 0 : 1),
      acknowledgement_of_receipt_date:          (acknowledgement_of_receipt_date.to_date rescue nil),
      facility_serial_number:                   nil,
      adoption_court_order:                     0,

    )

############################################## Client details end ####################################################

######################################### recording mother details (start) ###############################################

          if (parents_details_available == "Both" || parents_details_available == "Mother" || !mother_birthdate.blank?)

            core_person_mother = CorePerson.create(person_type_id: PersonType.where(name: 'Mother').first.id)

            person_mother = Person.create(person_id: core_person_mother.id,
                gender: "F",
                birthdate: (mother_birthdate.to_date rescue "1900-01-01".to_date))

            person_name_mother = PersonName.create(first_name: mother_first_name,
                middle_name: mother_middle_name,
                last_name: mother_last_name, person_id: core_person_mother.id)

            PersonNameCode.create(person_name_id: person_name_mother.id,
                first_name_code: mother_first_name.soundex,
                last_name_code: mother_last_name.soundex,
                middle_name_code: (mother_middle_name.soundex rescue nil))

            PersonRelationship.create(person_a: core_person.id, person_b: core_person_mother.id,
                person_relationship_type_id: PersonRelationType.where(name: 'Mother').first.id)


            PersonAddress.create(person_id: core_person_mother.id,
                                 current_village: Location.where(name: mother_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: Location.where(name: mother_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: Location.where(name: mother_current_district).first.location_id,
                                 current_district_other: "",
                                 home_village: Location.where(name: mother_home_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: Location.where(name: mother_home_ta).first.location_id,
                                 home_ta_other: "",
                                 home_district: Location.where(name: mother_current_district).first.location_id,
                                 home_district_other: "",
                                 citizenship: Location.where(name: mother_residental_country).first.location_id,
                                 residential_country: Location.where(name: mother_residental_country).first.location_id) rescue nil
          end

############################################ recording mother details (end)   ###############################################

########################################### recording father details (start) ###############################################

          if(details_of_father_known == "Yes" || parents_details_available == "Both" ||
              parents_details_available == "Father" || !father_birthdate.blank?)

              #raise params[:person][:father].inspect
              #raise father_home_village.inspect

            core_person_father = CorePerson.create(person_type_id: PersonType.where(name: 'Father').first.id)

            person_father = Person.create(person_id: core_person_father.id,
                gender: "M",
                birthdate: (father_birthdate.to_date rescue "1900-01-01".to_date))

            person_name_father = PersonName.create(first_name: father_first_name,
                middle_name: (father_middlename rescue nil),
                last_name: father_last_name, person_id: core_person_father.id)

            PersonNameCode.create(person_name_id: person_name_father.id,
                first_name_code: father_first_name.soundex,
                last_name_code: father_last_name.soundex,
                middle_name_code: (father_middlename.soundex rescue nil))

            PersonRelationship.create(person_a: core_person.id, person_b: core_person_father.id,
                person_relationship_type_id: PersonRelationType.where(name: 'Father').first.id)



            record = PersonAddress.new(person_id: core_person_father.id,
                                 current_village: Location.where(name: father_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: Location.where(name: father_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: Location.where(name: father_current_district).first.location_id,
                                 current_district_other: "",
                                 home_village: Location.where(name: father_home_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: Location.where(name: father_home_ta).first.location_id,
                                 home_ta_other: "",
                                 home_district: Location.where(name: father_current_district).first.location_id,
                                 home_district_other: "",
                                 citizenship: Location.where(name: father_residental_country).first.location_id,
                                 residential_country: Location.where(name: father_residental_country).first.location_id)
            record.save


          end

############################################# recording father details (end)   ###############################################

######################################### Recording informant details #############################################



    if (informant_same_as_mother == "Yes")



          PersonRelationship.create(person_a: core_person.id, person_b: core_person_mother.id,
              person_relationship_type_id: PersonRelationType.where(name: 'Informant').first.id)
              informant_id = core_person_mother.id

           ## here in this block of code, the assumption is that the address details for the mother have been saved since the
           ## motherther is the same as the informant, hence commenting the below code

=begin
          PersonAddress.create(person_id: core_person_mother.id,
                                     current_village: Location.where(name: mother_current_village).first.location_id,
                                     current_village_other: "",
                                     current_ta: Location.where(name: mother_current_ta).first.location_id,
                                     current_ta_other: "",
                                     current_district: Location.find_by_name(mother_current_district).location_id,
                                     current_district_other: "",
                                     home_village: Location.where(name:mother_current_village).first.location_id,
                                     home_village_other: "",
                                     home_ta: Location.where(name:mother_current_ta).first.location_id,
                                     citizenship: Location.where(name: mother_residental_country).first.location_id,
                                     residential_country: Location.where(name: mother_residental_country).first.location_id,
                                     address_line_1: informant_addressline1,
                                     address_line_2: informant_addressline2)
=end

    elsif (informant_same_as_father == "Yes")

          PersonRelationship.create(person_a: core_person.id, person_b: core_person_father.id,
              person_relationship_type_id: PersonRelationType.where(name: 'Informant').first.id)
              informant_id = core_person_father.id

           ## here in this block of code, the assumption is that the address details for the mother have been saved since the
           ## motherther is the same as the informant, hence commenting the below code

=begin
          PersonAddress.create(person_id: core_person_father.id,
                                 current_village: Location.where(name: father_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: Location.where(name: father_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: Location.find_by_name(father_current_district).location_id,
                                 current_district_other: "",
                                 home_village: Location.where(name:father_current_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: Location.where(name:father_current_ta).first.location_id,
                                 citizenship: Location.where(name: father_residental_country).first.location_id,
                                 residential_country: Location.where(name: father_residental_country).first.location_id,
                                 address_line_1: informant_addressline1,
                                 address_line_2: informant_addressline2)
=end

   elsif !informant_first_name.blank?



            core_person_informant = CorePerson.create(person_type_id: PersonType.where(name: 'Informant').first.id)
            informant_id = core_person_informant.id
            person_informant = Person.create(person_id: core_person_informant.id,
                gender: "N/A",
                birthdate: ("1900-01-01".to_date))

            #raise informant_first_name.inspect

            person_name_informant = PersonName.create(first_name: informant_first_name,
                middle_name: (informant_middle_name rescue nil),
                last_name: informant_last_name, person_id: core_person_informant.id)
            begin

              PersonNameCode.create(person_name_id: person_name_informant.id,
                first_name_code: informant_first_name.soundex,
                last_name_code: informant_last_name.soundex,
                middle_name_code: (informant_middle_name.soundex rescue nil))
            rescue

            end

            PersonRelationship.create(person_a: core_person.id, person_b: core_person_informant.id,
                person_relationship_type_id: PersonType.where(name: 'Informant').first.id)

            #raise informant_current_village.inspect

            PersonAddress.create(person_id: core_person_informant.id,
                                 current_village: informant_current_village == '' ? '' : Location.where(name: informant_current_village).first.location_id,
                                 current_village_other: "",
                                 current_ta: informant_current_ta == '' ? '' : Location.where(name: informant_current_ta).first.location_id,
                                 current_ta_other: "",
                                 current_district: informant_current_district == '' ? '' : Location.find_by_name(informant_current_district).location_id,
                                 current_district_other: "",
                                 home_village: informant_current_village == '' ? '' : Location.where(name:informant_current_village).first.location_id,
                                 home_village_other: "",
                                 home_ta: informant_current_ta == '' ? '' : Location.where(name:informant_current_ta).first.location_id,
                                 citizenship: Location.where(name: 'Malawi').first.location_id,
                                 residential_country: Location.where(name: 'Malawi').first.location_id,
                                 address_line_1: informant_addressline1,
                                 address_line_2: informant_addressline2)

  end

  ############################################## Informant details end #############################################
  ############################################## person status record ####################################################
 if is_record_a_duplicate.present?
    if SETTINGS["application_mode"] == "FC"
      PersonRecordStatus.new_record_state(core_person.id, 'FC-POTENTIAL DUPLICATE')
    else
      PersonRecordStatus.new_record_state(core_person.id, 'DC-POTENTIAL DUPLICATE')
    end

    potential_duplicate = PotentialDuplicate.create(person_id: core_person.id,created_at: (Time.now))
    if potential_duplicate.present?
         is_record_a_duplicate.split("|").each do |id|
            potential_duplicate.create_duplicate(id)
         end
    end
 else
    PersonRecordStatus.new_record_state(core_person.id, 'DC-ACTIVE')
 end

  ############################################# Person status record (end) ##############################################
  ############################################### person address details ###############################################


  #############################################Person address details(end) ###############################################

 end

    return @person

end

  def self.mother(person_id)
    result = nil
    #raise person_id.inspect
    relationship_type = PersonRelationType.find_by_name("Mother")

   # raise relationship_type.id.inspect

    relationship = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => relationship_type.id).last
    #raise relationship.person_b.inspect
    unless relationship.blank?
      result = PersonName.where(:person_id => relationship.person_b).last
    end

    result
  end

  def self.mother_address(person_id)
    result = nil
    #raise person_id.inspect
    relationship_type = PersonRelationType.find_by_name("Mother")

    # raise relationship_type.id.inspect

    relationship = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => relationship_type.id).last
    #raise relationship.person_b.inspect
    unless relationship.blank?
      result = PersonAddress.where(:person_id => relationship.person_b).last
    end

    result
  end

  def self.father_address(person_id)
    result = nil
    #raise person_id.inspect
    relationship_type = PersonRelationType.find_by_name("Father")

    # raise relationship_type.id.inspect

    relationship = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => relationship_type.id).last
    #raise relationship.person_b.inspect
    unless relationship.blank?
      result = PersonAddress.where(:person_id => relationship.person_b).last
    end

    result
  end

  def self.informant(person_id)
    result = nil
    #raise person_id.inspect
    relationship_type = PersonRelationType.find_by_name("Informant")

    relationship = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => relationship_type.id).last
    #raise relationship.person_b.inspect
    unless relationship.blank?
      result = PersonName.where(:person_id => relationship.person_b).last
    end

    result
  end

  def self.is_num?(val)

    #checks if the val is numeric or string
      !!Integer(val)
    rescue ArgumentError, TypeError
      false

  end

  def self.father(person_id)
    result = nil
    relationship_type = PersonRelationType.find_by_name("Father")
    relationship = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => relationship_type.id).last
    if !relationship.blank?
      result = PersonName.where(:person_id => relationship.person_b).last
    end

    result
  end

  def self.query_for_display(states, types=['Normal', 'Abandoned', 'Adopted', 'Orphaned'])

    state_ids = states.collect{|s| Status.find_by_name(s).id} + [-1]

    person_reg_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]

    main = Person.find_by_sql(
        "SELECT n.*, prs.status_id, pbd.district_id_number AS ben, p.gender, p.birthdate, pbd.national_serial_number AS brn FROM person p
            INNER JOIN core_person cp ON p.person_id = cp.person_id
            INNER JOIN person_name n ON p.person_id = n.person_id
            INNER JOIN person_record_statuses prs ON p.person_id = prs.person_id AND COALESCE(prs.voided, 0) = 0
            INNER JOIN person_birth_details pbd ON p.person_id = pbd.person_id
          WHERE prs.status_id IN (#{state_ids.join(', ')})
            AND pbd.birth_registration_type_id IN (#{person_reg_type_ids.join(', ')})
          GROUP BY p.person_id
          ORDER BY p.pbd.district_id_number ASC
           "
    )

    results = []

    main.each do |data|

      mother = self.mother(data.person_id)
      father = self.father(data.person_id)
      details = PersonBirthDetail.find_by_person_id(data.person_id)
      #For abandoned cases mother details may not be availabe
      #next if mother.blank?
      #next if mother.first_name.blank?
      #The form treat Father as optional
      #next if father.blank?
      #next if father.first_name.blank?
      name          = ("#{data['first_name']} #{data['middle_name']} #{data['last_name']}")
      mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
      father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
      results << {
          'id' => data.person_id,
          'ben' => data.ben,
          'brn' => details.brn,
          'gender' => data.gender,
          'dob' => data.birthdate.strftime('%d/%b/%Y'),
          'name'        => name,
          'father_name'       => father_name,
          'mother_name'       => mother_name,
          'status'            => Status.find(data.status_id).name, #.gsub(/DC\-|FC\-|HQ\-/, '')
          'date_of_reporting' => data['created_at'].to_date.strftime("%d/%b/%Y"),
      }
    end
    results

  end

  def self.query_for_crossmatch(birth_district, reg_facilities, start_date, end_date, params={})
    main = Person.order("pbd.created_at")
    search_val = params[:search][:value].blank? ? '_' : params[:search][:value]

    faulty_ids = [-1] + PersonRecordStatus.find_by_sql("SELECT prs.person_record_status_id FROM person_record_statuses prs
                                                LEFT JOIN person_record_statuses prs2 ON prs.person_id = prs2.person_id AND prs.voided = 0 AND prs2.voided = 0
                                                WHERE prs.created_at < prs2.created_at;").map(&:person_record_status_id)

    main = main.joins("
            INNER JOIN core_person cp ON person.person_id = cp.person_id
            INNER JOIN person_name n ON person.person_id = n.person_id
            INNER JOIN person_record_statuses prs ON person.person_id = prs.person_id
                 AND COALESCE(prs.voided, 0) = 0 AND prs.person_record_status_id NOT IN (#{faulty_ids.join(', ')})
            INNER JOIN person_birth_details pbd ON person.person_id = pbd.person_id ")

    results = []

    main = main.where("pbd.location_created_at IN (#{reg_facilities.join(', ')}) AND district_of_birth = #{birth_district}
            AND DATE(pbd.created_at) BETWEEN '#{start_date}' AND '#{end_date}' AND pbd.district_id_number IS NOT NULL
            AND concat_ws('_', pbd.national_serial_number, pbd.district_id_number, n.first_name, n.middle_name, n.last_name,
                DATE_FORMAT(person.birthdate, '%d/%b/%Y'), person.gender) REGEXP \"#{search_val}\" ")

    total = main.select(" count(*) c ")[0]['c']
    page = (params[:start].to_i / params[:length].to_i) + 1

    main = main.select(" n.*, prs.status_id, pbd.district_id_number, person.gender, person.birthdate, pbd.national_serial_number AS brn ")

    data = main.page(page)
    .per_page(params[:length].to_i)

    data.each do |data|

      mother = self.mother(data.person_id)
      father = self.father(data.person_id)
      name          = ("#{data['first_name']} #{data['middle_name']} #{data['last_name']}")
      mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
      father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
      results << [
          data.district_id_number,
          name,
          data.gender,
          data.birthdate.strftime('%d/%b/%Y'),
          mother_name,
          father_name,
          data.person_id
      ]
    end

    {
        "draw" => params[:draw].to_i,
        "recordsTotal" => total,
        "recordsFiltered" => total,
        "data" => results
    }
  end

  def self.record_complete?(child)
      name = PersonName.find_by_person_id(child.id)
      pbs = PersonBirthDetail.find_by_person_id(child.id) rescue nil
      birth_type = BirthRegistrationType.find(pbs.birth_registration_type_id).name rescue nil
      mother_name = self.mother(child.id)
      father_name = self.father(child.id)
      complete = false

      return false if pbs.blank?

      if name.first_name.blank?
        return complete
      end

      if name.last_name.blank?
        return complete
      end

      if (child.birthdate.to_date.blank? rescue true)
          return complete
      end

      if child.gender.blank? || child.gender == 'N/A'
        return complete
      end

      if birth_type.downcase == "normal"

        if mother_name.first_name.blank?
          return complete
        end

        if mother_name.last_name.blank?
          return complete
        end

      end

      if pbs.parents_married_to_each_other.to_s == '1'
        if father_name.first_name.blank?
          return complete
        end

        if father_name.last_name.blank?
          return complete
        end
      end

      return true

  end

  def self.by_ben(params, ben)

    person_ids = PersonBirthDetail.find_by_sql(" SELECT person_id FROM person_birth_details WHERE district_id_number = '#{ben}' ").map(&:person_id).uniq
    if person_ids.blank?
      old_ben_type_id = PersonIdentifierType.where(name: "Old Birth Entry Number").first.id
      person_ids = PersonIdentifier.find_by_sql("SELECT person_id FROM person_identifiers WHERE person_identifier_type_id = #{old_ben_type_id}
                    AND voided = 0 AND value = '#{ben}' ").map(&:person_id).uniq
    end

    if person_ids.blank?
      return {
          "draw" => 0,
          "recordsTotal" => 0,
          "recordsFiltered" => 0,
          "data" => []}
    else
      results = []
      person_ids.each do |id|
        p = Person.find(id)
        n = PersonName.where(person_id: id).last
        mother = Person.find(id).mother.person_names.last rescue nil
        father = Person.find(id).father.person_names.last rescue nil
        details = PersonBirthDetail.find_by_person_id(id)
        name          = ("#{n['first_name']} #{n['middle_name']} #{n['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
        row = [
            details.brn,
            details.district_id_number,
            "#{name} (#{p.gender})",
            p.birthdate.strftime('%d/%b/%Y'),
            mother_name,
            father_name,
            details.date_reported.strftime('%d/%b/%Y'),
            PersonRecordStatus.status(id),
            id
        ]
        results << row
      end

      return {
          "draw" => params[:draw].to_i,
          "recordsTotal" => results.length,
          "recordsFiltered" => results.length,
          "data" => results}
    end
  end

  def self.by_brn(params, brn)

    brn_num = 0
    if brn.to_s.length == 11
      brn_num = (brn.split("")[0 .. 5] + brn.split("")[7 .. 100]).join("").to_i
    end

    person_ids = PersonBirthDetail.find_by_sql(" SELECT person_id FROM person_birth_details WHERE national_serial_number = '#{brn_num}' ").map(&:person_id).uniq
    if person_ids.blank?
      old_ben_type_id = PersonIdentifierType.where(name: "Old Birth Registration Number").first.id
      person_ids = PersonIdentifier.find_by_sql("SELECT person_id FROM person_identifiers WHERE person_identifier_type_id = #{old_ben_type_id}
                    AND voided = 0 AND value = '#{brn}' ").map(&:person_id).uniq
    end

    if person_ids.blank?
      return {
          "draw" => 0,
          "recordsTotal" => 0,
          "recordsFiltered" => 0,
          "data" => []}
    else
      results = []
      person_ids.each do |id|
        p = Person.find(id)
        n = PersonName.where(person_id: id).last
        mother = Person.find(id).mother.person_names.last rescue nil
        father = Person.find(id).father.person_names.last rescue nil
        details = PersonBirthDetail.find_by_person_id(id)
        name          = ("#{n['first_name']} #{n['middle_name']} #{n['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
        row = [
            details.brn,
            details.district_id_number,
            "#{name} (#{p.gender})",
            p.birthdate.strftime('%d/%b/%Y'),
            mother_name,
            father_name,
            details.date_reported.strftime('%d/%b/%Y'),
            PersonRecordStatus.status(id),
            id
        ]
        results << row
      end

      return {
          "draw" => params[:draw].to_i,
          "recordsTotal" => results.length,
          "recordsFiltered" => results.length,
          "data" => results}
    end
  end

  def self.by_names(params, names)

    query = "voided = 0"
    names.each{|k, v|
      next if v.blank?
      query += " AND #{k} = \"#{v}\" "
    }

    person_ids = []
    if query == "voided = 0"
      return {
          "draw" => 0,
          "recordsTotal" => 0,
          "recordsFiltered" => 0,
          "data" => []}
    else
      person_ids = PersonName.where(" voided = 0 AND #{query} ").map(&:person_id).uniq
    end

    if person_ids.blank?
      return {
          "draw" => 0,
          "recordsTotal" => 0,
          "recordsFiltered" => 0,
          "data" => []}
    else
      results = []
      person_ids.each do |id|
        details = PersonBirthDetail.find_by_person_id(id)
        next if details.blank?

        p = Person.find(id)
        n = PersonName.where(person_id: id).last
        mother = Person.find(id).mother.person_names.last rescue nil
        father = Person.find(id).father.person_names.last rescue nil
        name          = ("#{n['first_name']} #{n['middle_name']} #{n['last_name']}")
        mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
        father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
        row = [
            details.brn,
            details.district_id_number,
            "#{name} (#{p.gender})",
            p.birthdate.strftime('%d/%b/%Y'),
            mother_name,
            father_name,
            details.date_reported.strftime('%d/%b/%Y'),
            PersonRecordStatus.status(id),
            id
        ]
        results << row
      end

      return {
          "draw" => params[:draw].to_i,
          "recordsTotal" => results.length,
          "recordsFiltered" => results.length,
          "data" => results}
    end
  end

  def self.search_results(params={})

    filters = params[:filter]

    if filters.blank?
      {
          "draw" => 0,
          "recordsTotal" => 0,
          "recordsFiltered" => 0,
          "data" => []}
    end
    entry_num_query = ''; fac_serial_query = ''; serial_num_query = ''; name_query = ''; limit = ' '
    limit = ' LIMIT 10 ' if filters.blank?
    gender_query = ''; place_of_birth_query = ''; status_query=''; date_issued_query=''

    types = []
    if params[:type] == 'All' || params[:type].blank?
      types=['Normal', 'Abandoned', 'Adopted', 'Orphaned']
    else
      types=[params[:type]]
    end

    person_reg_type_ids = BirthRegistrationType.where(" name IN ('#{types.join("', '")}')").map(&:birth_registration_type_id) + [-1]
    old_brn_identifier_join = " "
    old_brn_type_id = PersonIdentifierType.where(name: "Old Birth Registration Number").first.id

    old_ben_identifier_join = " "
    old_ben_type_id = PersonIdentifierType.where(name: "Old Birth Entry Number").first.id

    (filters || []).each do |k, v|

      v = v.strip rescue v
      case k
        when 'ben'
          legacy = PersonIdentifier.where(value: v, person_identifier_type_id: old_ben_type_id)
          legacy_available = PersonIdentifier.where(value: v, person_identifier_type_id: old_ben_type_id).length > 0
          if legacy_available
            old_ben_identifier_join = " INNER JOIN person_identifiers pid2 ON pid2.person_id = cp.person_id AND pid2.value = '#{v}' "
          else
            entry_num_query = " AND pbd.district_id_number = '#{v}' " unless v.blank?
          end
        when 'brn'

          legacy = PersonIdentifier.where(value: v, person_identifier_type_id: old_brn_type_id)
          legacy_available = legacy.length > 0
          if legacy_available
            old_brn_identifier_join = " INNER JOIN person_identifiers pid ON pid.person_id = cp.person_id AND pid.value = #{v} "
          else
            hf = (v.length / 2) rescue ""
            v = (v[0 .. (hf -1)] + v[(hf + 1) .. v.length]) rescue ""
            serial_num_query = " AND pbd.national_serial_number = '#{v}' " unless v.blank?
          end
        when 'serial_num'
          fac_serial_query =  " AND pbd.facility_serial_number = '#{v}' " unless v.blank?
        when 'names'
          if v["last_name"].present?
            name_query += " AND  n.last_name = \"#{v["last_name"]}\" "
          end
          if v["middle_name"].present?
            name_query += " AND n.middle_name = \"#{v["last_name"]}\" "
          end
          if v["first_name"].present?
            name_query += " AND n.first_name = \"#{v["first_name"]}\" "
          end
        when 'gender'
          gender_query = " AND person.gender = '#{v}' "  unless v.blank?
        when 'place'
          place_id = Location.locate_id_by_tag(v, 'Place of Birth')
          if place_id.present?
            place_of_birth_query = " AND  place_of_birth = #{place_id} "
          end
          district_id = Location.locate_id_by_tag(filters['district_of_birth'], 'District') rescue nil
          if district_id.present?
            place_of_birth_query += " AND  district_of_birth = #{district_id} "
          end
          ta_id = Location.locate_id(filters['ta_of_birth'], 'Traditional Authority', district_id) rescue nil
          if ta_id.present?
            village_id = Location.locate_id(filters['village_of_birth'], 'Village', ta_id)
            place_of_birth_query += " AND  birth_location_id = #{village_id} "
          end

          hospital_id = Location.locate_id(Location.find(filters['hospital_of_birth']).name, 'Health Facility', district_id) rescue nil
          if hospital_id.present?
            place_of_birth_query += " AND  birth_location_id = #{hospital_id} "
          end

          if filters["other_birth_place"].present?
            place_of_birth_query += " AND  other_birth_location = '#{v["other_birth_place"].strip}' "
          end
        when 'status'
          status_query = " AND prs.status_id = #{v} "  unless v.blank?
        when 'start_date'
          if filters['start_date'].present? && filters['end_date'].present?
            start_date = filters['start_date']
            end_date = filters['end_date']
            id = Status.find_by_name('HQ-DISPATCHED').status_id
            date_issued_query +=  "AND prs.status_id = #{id} AND prs.created_at BETWEEN '#{start_date}' AND '#{end_date}' "
          end
      end
    end

    had_query = ' '
    if !params['had'].blank?
      prev_states = params['had'].split('|')
      prev_state_ids = prev_states.collect{|sn| Status.where(name: sn).last.id  rescue -1 }
      had_query = " INNER JOIN person_record_statuses prev_s ON prev_s.person_id = prs.person_id
            AND prs.created_at <= prev_s.created_at AND prev_s.status_id IN (#{prev_state_ids.join(', ')})"
    end

    search_val = params[:search][:value] rescue nil
    search_val = '_' if search_val.blank?

    main =   Person.order(" person.updated_at DESC ")
    main = main.joins(" INNER JOIN core_person cp ON person.person_id = cp.person_id
            INNER JOIN person_name n ON person.person_id = n.person_id
            INNER JOIN person_record_statuses prs ON person.person_id = prs.person_id
            #{old_brn_identifier_join}
            #{old_ben_identifier_join}
             #{had_query}
            INNER JOIN person_birth_details pbd ON person.person_id = pbd.person_id ")

    main = main.where(" COALESCE(prs.voided, 0) = 0
            AND prs.created_at = (SELECT MAX(created_at) FROM person_record_statuses prs2 WHERE prs2.person_id = person.person_id)
            AND pbd.birth_registration_type_id IN (#{person_reg_type_ids.join(', ')})
            #{entry_num_query} #{fac_serial_query} #{serial_num_query}  #{name_query} #{gender_query} #{place_of_birth_query} #{status_query}
           AND concat_ws('_', pbd.national_serial_number, pbd.district_id_number, n.first_name, n.last_name, n.middle_name,
                person.birthdate, person.gender) REGEXP  \"#{search_val}\" ")

    total = main.select(" count(*) c ")[0]['c'] rescue 0
    page = (params[:start].to_i / params[:length].to_i) + 1

    data = main.group(" prs.person_id ")

    data = data.select(" n.*, prs.status_id, pbd.district_id_number AS ben, person.gender, person.birthdate, pbd.national_serial_number AS brn, pbd.date_reported")
    data = data.page(page)
    .per_page(params[:length].to_i)

    results = []

    data.each do |p|
      mother = Person.find(p.person_id).mother.person_names.last rescue nil
      father = Person.find(p.person_id).father.person_names.last rescue nil
      details = PersonBirthDetail.find_by_person_id(p.person_id)

      name          = ("#{p['first_name']} #{p['middle_name']} #{p['last_name']}")
      mother_name   = ("#{mother.first_name rescue 'N/A'} #{mother.middle_name rescue ''} #{mother.last_name rescue ''}")
      father_name   = ("#{father.first_name rescue 'N/A'} #{father.middle_name rescue ''} #{father.last_name rescue ''}")
      row = [
          details.brn,
          p.ben,
          "#{name} (#{p.gender})",
          p.birthdate.strftime('%d/%b/%Y'),
          mother_name,
          father_name,
          p.date_reported.strftime('%d/%b/%Y'),
          Status.find(p.status_id).name,
          p.person_id
      ]
      results << row
    end
    {
        "draw" => params[:draw].to_i,
        "recordsTotal" => total,
        "recordsFiltered" => total,
        "data" => results}
  end

  def self.create_nris_person(nris_person)

=begin
    {
        "Surname"=> "Kenneth",
        "OtherNames"=> "Moses",
        "FirstName"=> "Masula",
        "DateOfBirthString"=>"02/12/2017",
        "Sex"=> 1,
        "Nationality"=> "MWI",
        "Nationality2"=> "",
        "Status"=>0,
        "MotherPin"=> '4BSBY839',
        "MotherSurname"=> "Banda",
        "MotherMaidenName"=> "Mwandala",
        "MotherFirstName"=> "Zeliya",
        "MotherOtherNames"=>"Julia",
        "MotherNationality"=>"MWI",
        "FatherPin"=> "4BSBY810",
        "FatherSurname"=> "Kapundi",
        "FatherFirstName"=> "Kangaonde",
        "FatherOtherNames"=> "Masula",
        "FatherVillageId"=>-1,
        "FatherNationality"=>"MWI",
        "EbrsPk"=> nil,
        "NrisPk"=>nil,
        "PlaceOfBirthDistrictId"=>-1,
        "PlaceOfBirthDistrictName" => "Lilongwe",
        "PlaceOfBirthTAName" => "Maluwa",
        "PlaceOfBirthVillageName" => "Maluwa",
        "PlaceOfBirthVillageId"=>-1,
        "MotherDistrictId"=>-1,
        "MotherDistrictName"=> "Lilongwe",
        "MotherTAName"=> "Chadza",
        "MotherVillageName"=> "Kaphantengo",
        "MotherVillageId"=>-1,
        "FatherDistrictId"=> -1,
        "FatherDistrictName"=> "Lilongwe",
        "FatherTAName" => "Chadza",
        "FatherVillageName" => "Masula",
        "EditUser"=> "Dataman1",
        "EditMachine"=>"192.168.43.5",
        "BirthCertificateNumber"=> "00000200001",
        "DistrictOfRegistration" => "Lilongwe"
    }
=end
    user_id = User.where(username: "admin279").last.id
    codes = JSON.parse(File.read("#{Rails.root}/db/code2country.json"))

    # create core_person
    core_person = CorePerson.create(
        :person_type_id     => PersonType.where(name: 'Client').last.id,
    )

    ebrs_person = core_person
    #create person

    person = Person.create(
        :person_id          => core_person.id,
        :gender             => nris_person[:Sex].upcase.first == "M" ? 'M' : 'F',
        :birthdate          => nris_person[:DateOfBirthString].to_date.to_s
    )

    #create person_name
    PersonName.create(
        :person_id          => core_person.id,
        :first_name         => nris_person[:FirstName],
        :middle_name        => nris_person[:OtherNames],
        :last_name          => nris_person[:Surname]
    )

    #create person_birth_detail
    other_place = nil
    district_id = Location.locate_id_by_tag(nris_person["PlaceOfBirthDistrictName"], "District")
    ta_id = Location.locate_id(nris_person["PlaceOfBirthTAName"], "Traditional Authority", district_id)
    village_id = Location.locate_id(nris_person["PlaceOfBirthVillageName"], "Village", ta_id)
    reg_type = BirthRegistrationType.where(name: "Normal").last.id

    if village_id.blank?
      other_place = nris_person["PlaceOfBirthVillageName"]
      village_id = Location.locate_id_by_tag("Other", "Place Of Birth")
    end

    details = PersonBirthDetail.create(
        person_id: core_person.id,
        birth_registration_type_id: reg_type,
        place_of_birth:  Location.locate_id_by_tag("Home", "Place Of Birth"),
        birth_location_id: village_id,
        district_of_birth:  district_id,
        other_birth_location: other_place,
        type_of_birth: PersonTypeOfBirth.where(name: "Unknown").last.id,
        mode_of_delivery_id: ModeOfDelivery.where(name: "Unknown").last.id,
        location_created_at: Location.locate_id_by_tag(nris_person["DistrictOfRegistration"], "District"),
        acknowledgement_of_receipt_date: nris_person["DateRegistered"].to_date.to_s,
        date_reported: nris_person["DateRegistered"].to_date.to_s,
        date_registered: nris_person["DateRegistered"].to_date.to_s,
        level_of_education_id: LevelOfEducation.where(name: "Unknown").last.id,
        flagged: 1,
        creator: user_id,
        source_id: nris_person['id']
    )

    PersonIdentifier.create(
        person_id: core_person.id,
        person_identifier_type_id: (PersonIdentifierType.find_by_name("NRIS ID").id),
        value: nris_person[:NrisPk]
    )

    #create_mother
    #create mother_core_person
    exi_mother = PersonIdentifier.where(value: nris_person[:MotherPin], voided: 0).first

    if !exi_mother.blank?
      core_person = CorePerson.where(person_id: exi_mother.person_id).first
      mother_person = Person.where(person_id: exi_mother.person_id).first

      File.open("#{Rails.root}/existing_ids", "a"){|f|
        f.write(nris_person[:MotherPin])
      }
    else

      core_person = CorePerson.create(
          :person_type_id     => PersonType.where(name: 'Mother').last.id,
      )

      #create mother_person
      mother_person = Person.create(
          :person_id          => core_person.id,
          :gender             => 'F',
          :birthdate          =>  "1900-01-01",
          :birthdate_estimated => true
      )
      #create mother_name
      PersonName.create(
          :person_id          => core_person.id,
          :first_name         => nris_person[:MotherFirstName],
          :middle_name        => nris_person[:MotherMaidenName],
          :last_name          => nris_person[:MotherSurname]
      )
      #create mother_address
      m_district_id = Location.locate_id_by_tag(nris_person["MotherDistrictName"], "District")
      m_ta_id = Location.locate_id(nris_person["MotherTAName"], "Traditional Authority", district_id)
      m_village_id = Location.locate_id(nris_person["MotherVillageName"], "Village", ta_id)
      m_citizenship = Location.locate_id_by_tag(codes[nris_person["MotherNationality"].upcase], "Country")

      pam = PersonAddress.new(
          :person_id          => core_person.id,
          :home_district   => m_district_id,
          :home_ta            => m_ta_id,
          :home_village       => m_village_id,
          :citizenship        => m_citizenship,
          :residential_country => m_citizenship
      )

      pam.home_district_other = nris_person["MotherDistrictName"] if m_district_id.blank?
      pam.home_ta_other = nris_person["MotherTAName"] if m_ta_id.blank?
      pam.home_village_other = nris_person["MotherVillageName"] if m_village_id.blank?
      pam.save

      #create mother_identifier
      if nris_person[:MotherPin].present?

        PersonIdentifier.create(
            person_id: mother_person.person_id,
            person_identifier_type_id: (PersonIdentifierType.find_by_name("National ID Number").id),
            value: nris_person[:MotherPin].upcase.strip
        )
      end
    end
    # create mother_relationship
    PersonRelationship.create(
        person_a: ebrs_person.id, person_b: core_person.id,
        person_relationship_type_id: PersonRelationType.where(name: 'Mother').last.id
    )

    #create_father

    if nris_person[:FatherFirstName].present? && nris_person[:FatherSurname].present?

      exi_father = PersonIdentifier.where(value: nris_person[:FatherPin], voided: 0).first

      if !exi_father.blank?
        core_person = CorePerson.where(person_id: exi_father.person_id).first
        File.open("#{Rails.root}/existing_ids", "a"){|f|
          f.write(nris_person[:FatherPin])
        }
        #father_person = Person.where(person_id: exi_father.person_id).first
      else

        core_person = CorePerson.create(
            :person_type_id     => PersonType.where(name: 'Father').last.id,
        )

        #create father_person
        father_person = Person.create(
            :person_id          => core_person.id,
            :gender             => 'M',
            :birthdate          =>  "1900-01-01".to_date.to_s,
            :birthdate_estimated => true
        )
        #create father_name
        PersonName.create(
            :person_id          => core_person.id,
            :first_name         => nris_person[:FatherFirstName],
            :middle_name        => nris_person[:FatherOtherNames],
            :last_name          => nris_person[:FatherSurname]
        )

        #create father_address
        f_district_id = Location.locate_id_by_tag(nris_person["FatherDistrictName"], "District")
        f_ta_id = Location.locate_id(nris_person["FatherTAName"], "Traditional Authority", district_id)
        f_village_id = Location.locate_id(nris_person["FatherVillageName"], "Village", ta_id)
        f_citizenship = Location.locate_id_by_tag(codes[nris_person["FatherNationality"].upcase], "Country")

        paf = PersonAddress.new(
            :person_id          => core_person.id,
            :home_district  => f_district_id,
            :home_ta => f_ta_id,
            :home_village => f_village_id,
            :citizenship => f_citizenship,
            :residential_country => f_citizenship
        )

        paf.home_district_other = nris_person["FatherDistrictName"] if f_district_id.blank?
        paf.home_ta_other = nris_person["FatherTAName"]   if f_ta_id.blank?
        paf.home_village_other = nris_person["FatherVillageName"] if f_village_id.blank?
        paf.save

        #create father_identifier
        if nris_person[:FatherPin].present?

          PersonIdentifier.create(
              person_id: father_person.person_id,
              person_identifier_type_id: (PersonIdentifierType.find_by_name("National ID Number").id),
              value: nris_person[:FatherPin].upcase.strip
          )
        end
      end

      # create father_relationship
      PersonRelationship.create(
          person_a: ebrs_person.id,
          person_b: core_person.id,
          person_relationship_type_id: PersonRelationType.where(name: 'Father').last.id
      )
    end

=begin
    PersonRelationship.create(
        person_a: ebrs_person.id,
        person_b: mother_person.id,
        person_relationship_type_id: PersonRelationType.where(name: 'Informant').last.id
    )

    details.update_attribute("informant_relationship_to_person", "Mother")
=end

    return ebrs_person.id
  end


  def self.request_nris_id(person_id, client_address="N/A", cur_user)

    if SETTINGS["activate_nid_integration"].to_s != "true"
	    return "NID INTEGRATION NOT ACTIVATED"
    end

    nid_type = PersonIdentifierType.where(name: "National ID Number").first.id
    nris_type = PersonIdentifierType.where(name: "NRIS ID").first.id
    nid = nil
    nris_key = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nris_type)

    person = Person.find(person_id)
    if person.birthdate.to_date <= 16.years.ago.to_date
      return "AGE LIMIT EXCEEDED"
    end

    details = PersonBirthDetail.where(person_id: person_id).last
    b_name = PersonName.where(person_id: person_id).last

    m_type = PersonRelationType.find_by_name("Mother")
    m_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => m_type.id).last
    
    m_type = PersonRelationType.find_by_name("Adoptive-Mother") if m_rel.blank?
    m_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => m_type.id).last if m_rel.blank?

    m_name = PersonName.where(person_id: m_rel.person_b).last
    m_address = PersonAddress.where(person_id: m_rel.person_b).last
    m_home_district = Location.find(m_address.home_district) rescue nil
    m_home_ta = Location.find(m_address.home_ta) rescue nil
    m_home_village = Location.find(m_address.home_village) rescue nil
    m_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: m_rel.person_b).last.value rescue ""

    f_type = PersonRelationType.find_by_name("Father")
    f_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => f_type.id).last
    
    f_type = PersonRelationType.find_by_name("Adoptive-Father") if f_rel.blank? 
    f_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => f_type.id).last if f_rel.blank? 

    f_name = PersonName.where(person_id: f_rel.person_b).last rescue nil
    f_address = PersonAddress.where(person_id: f_rel.person_b).last rescue nil
    f_home_district = Location.find(f_address.home_district) rescue nil
    f_home_ta = Location.find(f_address.home_ta) rescue nil
    f_home_village = Location.find(f_address.home_village) rescue nil
    f_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: f_rel.person_b).last.value rescue ""


    inf_type = PersonRelationType.find_by_name("Informant")
    inf_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => inf_type.id).last

    inf_person = Person.where(person_id: inf_rel.person_b).last
    inf_name = PersonName.where(person_id: inf_rel.person_b).last
    inf_address = PersonAddress.where(person_id: inf_rel.person_b).last
    inf_home_district = Location.find(inf_address.home_district) rescue nil
    inf_home_ta = Location.find(inf_address.home_ta) rescue nil
    inf_home_village = Location.find(inf_address.home_village) rescue nil
    inf_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: inf_rel.person_b).last.value rescue ""

    
    codes = JSON.parse(File.read("#{Rails.root}/db/country2code.json"))

    get_url = SETTINGS['query_by_nid_address']
    post_url = SETTINGS['request_for_nid_address']

    nris_pkey = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nris_type).first rescue nil

    reg_type_id = {
        "Normal" => 0,
        "Abandoned" => 1,
        "Orphaned"  => 2,
        "Adopted"   => 3
    }[BirthRegistrationType.where(:birth_registration_type_id => details.birth_registration_type_id).first.name]

=begin
These Are Mandatory Fields, If One is Missing The Remote NID Server Will Return a Validation Message
   EditUser
   EditMachine
   Surname
   FirstName
   DateOfBirth
   Sex
   Nationality
   Status
   MotherSurname
   MotherFirstName
   MotherNationality
   PlaceOfBirthDistrictId
   BirthCertificateNumber
=end

    data = {
        "Surname"=> b_name.last_name,
        "OtherNames"=>b_name.middle_name,
        "FirstName"=>b_name.first_name,
        "DateOfBirthString"=>person.birthdate.to_date.strftime("%d/%m/%Y"),
        "Sex"=> person.gender == 'M' ? 1 : 2,
        "Nationality"=> (codes[Location.find(m_address.citizenship).name] rescue nil),
        "Nationality2"=> (codes[Location.find(f_address.citizenship).name] rescue nil),
        "Status"=>reg_type_id,
        "MotherPin"=>m_pin,
        "MotherSurname"=> m_name.last_name,
        "MotherMaidenName"=> m_name.last_name,
        "MotherFirstName"=>m_name.first_name,
        "MotherOtherNames"=>m_name.middle_name,
        "MotherVillageId"=>-1,
        "MotherNationality"=>(codes[Location.find(m_address.citizenship).name] rescue nil),
        "FatherPin"=>f_pin,
        "FatherSurname"=> (f_name.last_name rescue nil),
        "FatherFirstName"=> (f_name.first_name rescue nil),
        "FatherOtherNames"=> (f_name.middle_name rescue nil),
        "FatherVillageId"=>-1,
        "FatherNationality"=>(codes[Location.find(f_address.citizenship).name] rescue nil),
        "EbrsPk"=> person_id,
        "NrisPk"=> nris_pkey,
        "PlaceOfBirthDistrictId"=>-1,
        "PlaceOfBirthDistrictName"=> (Location.find(details.district_of_birth).district rescue nil),
        "PlaceOfBirthTAName" => (Location.find(details.birth_location_id).ta rescue nil),
        "PlaceOfBirthVillageName"=> (Location.find(details.birth_location_id).village rescue nil),
        "PlaceOfBirthVillageId"=>-1,
        "MotherDistrictId"=> (m_home_district.id rescue nil),
        "MotherDistrictName" => ((m_home_district.name rescue m_address.home_district_other) rescue nil),
        "MotherTAName" => ((m_home_ta.name rescue m_address.home_ta_other) rescue nil),
        "MotherVillageName" => ((m_home_village.name rescue m_address.home_village_other) rescue nil),
        "FatherDistrictId"=> (f_home_district.id rescue nil),
        "FatherDistrictName" => ((f_home_district.name rescue f_address.home_district_other) rescue nil),
        "FatherTAName" => ((f_home_ta.name rescue f_address.home_ta_other) rescue nil),
        "FatherVillageName" => ((f_home_village.name rescue f_address.home_village_other) rescue nil),
        "InformantPin"=> inf_pin,
        "InformantSurname"=> inf_name.last_name,
        "InformantFirstName"=> inf_name.first_name,
        "InformantOtherNames"=> inf_name.middle_name,
        "InformantNationality"=> (codes[Location.find(inf_address.citizenship).name] rescue nil),
        "InformantDistrictId"=> (inf_home_district.id rescue nil),
        "InformantDistrictName" => ((inf_home_district.name rescue inf_address.home_district_other) rescue nil),
        "InformantTAName" => ((inf_home_ta.name rescue inf_address.home_ta_other) rescue nil),
        "InformantVillageName" => ((inf_home_village.name rescue inf_address.home_village_other) rescue false),
        "InformantPhoneNumber" => (inf_person.get_attribute('Cell Phone Number') rescue nil),
        "InformantAddress" => ((inf_address.addressline1 + " " + inf_address.addressline2).strip rescue nil),
        "EditUser"=>("#{cur_user.username} (#{cur_user.first_name} #{cur_user.last_name})" rescue nil),
        "EditMachine"=> client_address,
        "BirthCertificateNumber"=> "#{details.brn}"
    }

    data.each do |k, v|
      data[k] = "" if v.blank?
    end

    if data['MotherNationality'] != "MWI" && data['FatherNationality'] != "MWI"
      return "NOT A MALAWIAN CITIZEN"
    end

    success = false;
    RestClient.post(post_url, data.to_json, :content_type => "application/json", :accept => 'json'){|response, request, result|
      #Save National ID

      res = JSON.parse(response) rescue response.to_s

      return "FAILED" if !res.match("#")
      array = res.split("#")
      nid = array[0]
      nid = nid.gsub("\"", '')
      puts "NID: #{nid}, LENGTH #{nid.length}"
      puts "NRIS KEY: #{array[1]}"
      return "FAILED" if nid.strip.length != 8

      puts res
      if nid.present? && nid.to_s.length == 8
        success = true
        old_id = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nid_type).last
        old_id = PersonIdentifier.new if old_id.blank?

        old_id.person_id = person_id
        old_id.person_identifier_type_id = nid_type
        old_id.value = nid
        old_id.save
      end

      if array[1].present?
        old_key = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nris_type).last
        old_key = PersonIdentifier.new if old_key.blank?

        old_key.person_id = person_id
        old_key.person_identifier_type_id = nris_type
        old_key.value = array[1]
        old_key.save
      end
    }

    return success
  end

  def self.process_arrays(person_ids, errors={}, client_address, cur_user)
    return [] if person_ids.blank?

    array = []
    codes = JSON.parse(File.read("#{Rails.root}/db/country2code.json"))
    person_ids.each do |person_id|
      errors[person_id] = [] if errors[person_id].blank?
      person = Person.find(person_id) rescue nil
      if person.blank?
        errors[person_id] << "MISSING RECORD"
        next
      end

      if person.birthdate.to_date <= 16.years.ago.to_date
        errors[person_id] << "AGE LIMIT EXCEEDED"
        next
      end

      details = PersonBirthDetail.where(person_id: person_id).last
      b_name = PersonName.where(person_id: person_id).last

      m_type = PersonRelationType.find_by_name("Mother")
      m_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => m_type.id).last

      m_name = PersonName.where(person_id: m_rel.person_b).last
      m_address = PersonAddress.where(person_id: m_rel.person_b).last
      m_home_district = Location.find(m_address.home_district) rescue nil
      m_home_ta = Location.find(m_address.home_ta) rescue nil
      m_home_village = Location.find(m_address.home_village) rescue nil
      m_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: m_rel.person_b).last.value rescue ""

      f_type = PersonRelationType.find_by_name("Father")
      f_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => f_type.id).last

      f_name = PersonName.where(person_id: f_rel.person_b).last rescue nil
      f_address = PersonAddress.where(person_id: f_rel.person_b).last rescue nil
      f_home_district = Location.find(f_address.home_district) rescue nil
      f_home_ta = Location.find(f_address.home_ta) rescue nil
      f_home_village = Location.find(f_address.home_village) rescue nil
      f_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: f_rel.person_b).last.value rescue ""


      inf_type = PersonRelationType.find_by_name("Informant")
      inf_rel = PersonRelationship.where(:person_a => person_id, :person_relationship_type_id => inf_type.id).last

      inf_person = Person.where(person_id: inf_rel.person_b).last rescue ""
      inf_name = PersonName.where(person_id: inf_rel.person_b).last rescue ""
      inf_address = PersonAddress.where(person_id: inf_rel.person_b).last rescue ""
      inf_home_district = Location.find(inf_address.home_district) rescue ""
      inf_home_ta = Location.find(inf_address.home_ta) rescue ""
      inf_home_village = Location.find(inf_address.home_village) rescue ""
      inf_pin = PersonIdentifier.where(person_identifier_type_id: nid_type, person_id: inf_rel.person_b).last.value rescue ""

      if (codes[Location.find(m_address.citizenship).name] rescue nil) != "MWI" && (codes[Location.find(f_address.citizenship).name] rescue nil) != "MWI"
        errors[person_id] << "NOT A MALAWIAN CITIZEN"
        next
      end

      nris_pkey = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nris_type).first rescue nil

      reg_type_id = {
          "Normal" => 0,
          "Abandoned" => 1,
          "Orphaned"  => 2,
          "Adopted"   => 3
      }[BirthRegistrationType.where(:birth_registration_type_id => details.birth_registration_type_id).first.name]

      data = {
          "Surname"=> b_name.last_name,
          "OtherNames"=>b_name.middle_name,
          "FirstName"=>b_name.first_name,
          "DateOfBirthString"=>person.birthdate.to_date.strftime("%d/%m/%Y"),
          "Sex"=> person.gender == 'M' ? 1 : 2,
          "Nationality"=> (codes[Location.find(m_address.citizenship).name] rescue nil),
          "Nationality2"=> (codes[Location.find(f_address.citizenship).name] rescue nil),
          "Status"=>reg_type_id,
          "MotherPin"=>m_pin,
          "MotherSurname"=> m_name.last_name,
          "MotherMaidenName"=> m_name.last_name,
          "MotherFirstName"=>m_name.first_name,
          "MotherOtherNames"=>m_name.middle_name,
          "MotherVillageId"=>-1,
          "MotherNationality"=>(codes[Location.find(m_address.citizenship).name] rescue nil),
          "FatherPin"=>f_pin,
          "FatherSurname"=> (f_name.last_name rescue nil),
          "FatherFirstName"=> (f_name.first_name rescue nil),
          "FatherOtherNames"=> (f_name.middle_name rescue nil),
          "FatherVillageId"=>-1,
          "FatherNationality"=>(codes[Location.find(f_address.citizenship).name] rescue nil),
          "EbrsPk"=> person_id,
          "NrisPk"=> nris_pkey,
          "PlaceOfBirthDistrictId"=>-1,
          "PlaceOfBirthDistrictName"=> (Location.find(details.district_of_birth).district rescue nil),
          "PlaceOfBirthTAName" => (Location.find(details.birth_location_id).ta rescue nil),
          "PlaceOfBirthVillageName"=> (Location.find(details.birth_location_id).village rescue nil),
          "PlaceOfBirthVillageId"=>-1,
          "MotherDistrictId"=> (m_home_district.id rescue nil),
          "MotherDistrictName" => ((m_home_district.name rescue m_address.home_district_other) rescue nil),
          "MotherTAName" => ((m_home_ta.name rescue m_address.home_ta_other) rescue nil),
          "MotherVillageName" => ((m_home_village.name rescue m_address.home_village_other) rescue nil),
          "FatherDistrictId"=> (f_home_district.id rescue nil),
          "FatherDistrictName" => ((f_home_district.name rescue f_address.home_district_other) rescue nil),
          "FatherTAName" => ((f_home_ta.name rescue f_address.home_ta_other) rescue nil),
          "FatherVillageName" => ((f_home_village.name rescue f_address.home_village_other) rescue nil),
          "InformantPin"=> inf_pin,
          "InformantSurname"=> (inf_name.last_name rescue nil),
          "InformantFirstName"=> (inf_name.first_name rescue nil),
          "InformantOtherNames"=> (inf_name.middle_name rescue nil),
          "InformantNationality"=> (codes[Location.find(inf_address.citizenship).name] rescue nil),
          "InformantDistrictId"=> (inf_home_district.id rescue nil),
          "InformantDistrictName" => ((inf_home_district.name rescue inf_address.home_district_other) rescue nil),
          "InformantTAName" => ((inf_home_ta.name rescue inf_address.home_ta_other) rescue nil),
          "InformantVillageName" => ((inf_home_village.name rescue inf_address.home_village_other) rescue false),
          "InformantPhoneNumber" => (inf_person.get_attribute('Cell Phone Number') rescue nil),
          "InformantAddress" => ((inf_address.addressline1 + " " + inf_address.addressline2).strip rescue nil),
          "EditUser"=>("#{cur_user.username} (#{cur_user.first_name} #{cur_user.last_name})" rescue nil),
          "EditMachine"=> client_address,
          "BirthCertificateNumber"=> "#{details.brn}"
      }

      data.each do |k, v|
        data[k] = "" if v.blank?
      end

      array << data
    end

    [array, errors]
  end

  def self.request_nris_ids_by_batch(person_ids, client_address="N/A", cur_user)

    if SETTINGS["activate_nid_integration"].to_s != "true"
      return "NID INTEGRATION NOT ACTIVATED"
    end

    nid_type = PersonIdentifierType.where(name: "National ID Number").first.id
    nris_type = PersonIdentifierType.where(name: "NRIS ID").first.id

    errors = {}
    batch, errors = self.process_arrays(person_ids, errors, client_address, cur_user)
    return false if batch.length == 0

    success = false
    post_url = SETTINGS['batch_request_for_nid_address']

    response = RestClient.post(post_url, batch.to_json, :content_type => "application/json", :accept => 'json')

    #process batch response
    response = JSON.parse(response) rescue nil
    (response || []).each do |res|
      puts res 
      return "FAILED" if !res.match("#")
      array = res.split("#")
      nid = array[0]
      nid = nid.gsub("\"", '')
      person_id = array[2]
      return "FAILED" if nid.strip.length != 8

      if nid.present? && nid.to_s.length == 8
        success = true
        old_id = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nid_type).last
        old_id = PersonIdentifier.new if old_id.blank?

        old_id.person_id = person_id
        old_id.person_identifier_type_id = nid_type
        old_id.value = nid
        old_id.save
      end

      if array[1].present?
        old_key = PersonIdentifier.where(person_id: person_id, person_identifier_type_id: nris_type).last
        old_key = PersonIdentifier.new if old_key.blank?

        old_key.person_id = person_id
        old_key.person_identifier_type_id = nris_type
        old_key.value = array[1]
        old_key.save
      end
    end

    return [success, errors]
  end

  def self.qr_code_data(person_id)
    person = Person.find(person_id)
    details = PersonBirthDetail.where(person_id: person_id).first

    birth_district = Location.find(details.district_of_birth).name rescue nil
    place_of_birth = Location.find(details.birth_location_id).name rescue details.other_place_of_birth

    if place_of_birth.downcase == 'other'
      place_of_birth = details.other_birth_location
    end
    if !place_of_birth.blank?
      place_of_birth += ", " + birth_district
    else
      place_of_birth = birth_district
    end

    str = "04~#{person.id_number}-#{details.district_id_number}-#{details.brn}"
    str += "~#{person.printable_name}~#{person.birthdate.to_date.strftime("%d-%b-%Y")}~#{person.gender}"
    str += "~#{place_of_birth}"
    str += ("~#{person.mother.printable_name}" rescue '~')
    str += ("~#{person.mother.citizenship}" rescue '~')
    str += ("~#{person.father.printable_name}" rescue '~')
    str += ("~#{person.father.citizenship}" rescue '~')
    str += ("~#{details.date_registered.to_date.strftime("%d-%b-%Y")}" rescue nil)

    str
  end

  def self.format_for_elastic_search(person_id)

    person = Person.find(person_id)
    name    = PersonName.where(person_id: person.person_id).last
    details = PersonBirthDetail.where(person_id: person.person_id).last
    mother  = PersonService.mother(person.person_id)
    father  = PersonService.father(person.person_id)
    mother_address = PersonAddress.where(person_id: mother.person_id).first rescue nil
    father_address = PersonAddress.where(person_id: father.person_id).first rescue nil

    nationality = ""
    if !mother_address.blank?
      nationality = Location.find(mother_address.citizenship).country
    end

    if nationality.blank? && !father_address.blank?
      nationality = Location.find(father_address.citizenship).country
    end

    loc       = Location.find(details.location_created_at)
    district  = loc.district rescue nil
    if district.blank? #For hospitals this is possible
      district = Location.find(loc.parent_location).name
    end

    person_hash       = {}
    person_hash["id"] = person_id
    person_hash["first_name"]= name.first_name rescue ''
    person_hash["last_name"] =  name.last_name rescue ''
    person_hash["middle_name"] = name.middle_name rescue ''
    person_hash["gender"] = {'F' => 'Female', 'M' => 'Male'}[person.gender]
    person_hash["birthdate"]= person.birthdate.to_date.to_s
    person_hash["birthdate_estimated"] = person.birthdate_estimated
    person_hash["nationality"]=  nationality
    person_hash["place_of_birth"] = Location.find(details.place_of_birth).name
    person_hash["district"] = district

    person_hash["mother_first_name"]= mother.first_name rescue nil
    person_hash["mother_last_name"] =  mother.last_name rescue nil
    person_hash["mother_middle_name"] = mother.middle_name rescue nil

    person_hash["mother_home_district"] = nil
    person_hash["mother_home_ta"] = nil
    person_hash["mother_home_village"] = nil

    person_hash["mother_current_district"] = nil
    person_hash["mother_current_ta"] = nil
    person_hash["mother_current_village"] = nil

    person_hash["father_first_name"]= father.first_name rescue nil
    person_hash["father_last_name"] =  father.last_name rescue nil
    person_hash["father_middle_name"] = father.middle_name rescue nil

    person_hash["father_home_district"] = nil
    person_hash["father_home_ta"] = nil
    person_hash["father_home_village"] = nil

    person_hash["father_current_district"] = nil
    person_hash["father_current_ta"] = nil
    person_hash["father_current_village"] = nil
    person_hash
  end

  def self.force_sync(person_id, models={})
    doc = Pusher.database.get(person_id.to_s)
    fixed = false

    $models = {}
    if !models.blank?
      $models = {}
    else
      Rails.application.eager_load!
      ActiveRecord::Base.send(:subclasses).map(&:name).each do |n|
        $models[eval(n).table_name] = n
      end
    end

    if !doc.blank?
        doc = doc.as_json
        ordered_keys = (['core_person', 'person', 'users', 'user_role'] +
          doc.keys.reject{|k| ['_id', 'change_agent', '_rev', 'change_location_id',
                               'ip_addresses', 'location_id', 'type', 'district_id'].include?(k)}).uniq

      begin
        (ordered_keys || []).each do |table|
          next if doc[table].blank?
          next if table == "notification"

          doc[table].each do |p_value, data|

            if data.has_key?("person_b")
              PersonService.force_sync(data['person_b'])
            end

            record = eval($models[table]).find(p_value) rescue nil
            if !record.blank?
              record.update_columns(data)
            else
              record =  eval($models[table]).create(data)
            end

          end
        end

        fixed = true
        ErrorRecords.where(person_id: person_id).each do |r|
          r.passed = 1
          r.save
        end

      rescue => e
        fixed = false
      end
    end

    fixed
  end
end
