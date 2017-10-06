require'migration-lib/migrate_child'
require 'migration-lib/migrate_mother'
require 'migration-lib/migrate_father'
require 'migration-lib/migrate_informant'
require'migration-lib/person_service'
@missing_district_ids = "#{Rails.root}/app/assets/data/missing_district_ids.txt"
@loaded_data = "#{Rails.root}/app/assets/data/loaded_data.txt"
@file_path = "#{Rails.root}/app/assets/data/missing_district_id_num_docs.txt"
@multiple_birth_file = "#{Rails.root}/app/assets/data/multiple_birth_children.json"
@failed_to_save = "#{Rails.root}/app/assets/data/failed_to_save.txt"
@suspected = "#{Rails.root}/app/assets/data/suspected.txt"
@analysis = "#{Rails.root}/app/assets/data/analysis.txt"
@missing_tas = "#{Rails.root}/app/assets/data/migration_issues/missing_tas.csv"
@missing_villages = "#{Rails.root}/app/assets/data/migration_issues/missing_villages.csv"
@missing_districts = "#{Rails.root}/app/assets/data/migration_issues/missing_districts.csv"
@missing_statuses = "#{Rails.root}/app/assets/data/migration_issues/missing_statuses.csv"
@missing_citizenships = "#{Rails.root}/app/assets/data/migration_issues/missing_citizenships.csv"
@missing_record_statuses = "#{Rails.root}/app/assets/data/migration_issues/missing_record_statuses.csv"
@missing_birth_type = "#{Rails.root}/app/assets/data/migration_issues/missing_birth_type.csv"
@missing_multiple_birth_ids = "#{Rails.root}/app/assets/data/migration_issues/missing_multiple_birth_ids.csv"
@missing_doc_creator = "#{Rails.root}/app/assets/data/migration_issues/missing_doc_creator.csv"

User.current = User.last

Duplicate_attribute_type_id = PersonAttributeType.where(name: 'Duplicate Ben').first.id

def write_log(file, content)

	if !File.exists?(file)
           file = File.new(file, 'w')
    else

       File.open(file, 'a') do |f|
          f.puts "#{content}"

      end


    end
end

def verify_location(owner, location_type, data)

	location_found = false

	if owner == "Mother"

		if location_type == "TA"
                cur_district_id  = Location.locate_id_by_tag(data[:person][:mother][:current_district], 'District')
                cur_ta_id        = Location.locate_id(data[:person][:mother][:current_ta], 'Traditional Authority', cur_district_id)
                home_district_id  = Location.locate_id_by_tag(data[:person][:mother][:home_district], 'District')
                home_ta_id        = Location.locate_id(data[:person][:mother][:home_ta], 'Traditional Authority', home_district_id)

                unless cur_ta_id.blank? || home_ta_id.blank?
                	location_found = true
                else
                    location_found = false
                end

		elsif location_type == "Village"

                cur_district_id  = Location.locate_id_by_tag(data[:person][:mother][:current_district], 'District')
                cur_ta_id        = Location.locate_id(data[:person][:mother][:current_ta], 'Traditional Authority', cur_district_id)
                cur_village_id   = Location.locate_id(data[:person][:mother][:current_village], 'Village', cur_ta_id)
                home_district_id  = Location.locate_id_by_tag(data[:person][:mother][:current_district], 'District')
                home_ta_id        = Location.locate_id(data[:person][:mother][:current_ta], 'Traditional Authority', home_district_id)
                home_village_id   = Location.locate_id(data[:person][:mother][:current_village], 'Village', home_ta_id)

                unless cur_village_id.blank? || home_village_id.blank?
                	location_found = true
                else
                    location_found = false
                end

		elsif location_type == "District"

             cur_district_id  = Location.locate_id_by_tag(data[:person][:mother][:current_district], 'District')
             home_district_id  = Location.locate_id_by_tag(data[:person][:mother][:home_district], 'District')

                unless cur_district_id.blank? || home_district_id.blank?
                	location_found = true
                else
                    location_found = false
                end
		else
			 citizenship = Location.where(country: data[:person][:mother][:citizenship]).last.id rescue nil
			 residential_country = Location.where(name: data[:person][:mother][:residential_country]).last.id rescue nil

             unless citizenship.blank? || residential_country.blank?
             	location_found = true
             else
             	location_found = false
             end
		end

	else

		if location_type == "TA"
                cur_district_id  = Location.locate_id_by_tag(data[:person][:father][:current_district], 'District')
                cur_ta_id        = Location.locate_id(data[:person][:father][:current_ta], 'Traditional Authority', cur_district_id)
                home_district_id  = Location.locate_id_by_tag(data[:person][:father][:home_district], 'District')
                home_ta_id        = Location.locate_id(data[:person][:father][:home_ta], 'Traditional Authority', home_district_id)

                unless cur_ta_id.blank? || home_ta_id.blank?
                	location_found = true
                else
                    location_found = false
                end

		elsif location_type == "Village"

                cur_district_id  = Location.locate_id_by_tag(data[:person][:father][:current_district], 'District')
                cur_ta_id        = Location.locate_id(data[:person][:father][:current_ta], 'Traditional Authority', cur_district_id)
                cur_village_id   = Location.locate_id(data[:person][:father][:current_village], 'Village', cur_ta_id)
                home_district_id  = Location.locate_id_by_tag(data[:person][:father][:current_district], 'District')
                home_ta_id        = Location.locate_id(data[:person][:father][:current_ta], 'Traditional Authority', home_district_id)
                home_village_id   = Location.locate_id(data[:person][:father][:current_village], 'Village', home_ta_id)

                unless cur_village_id.blank? || home_village_id.blank?
                	location_found = true
                else
                    location_found = false
                end

		elsif location_type == "District"

             cur_district_id  = Location.locate_id_by_tag(data[:person][:father][:current_district], 'District')
             home_district_id  = Location.locate_id_by_tag(data[:person][:father][:current_district], 'District')

                unless cur_district_id.blank? || home_district_id.blank?
                	location_found = true
                else
                    location_found = false
                end
        else
        	 citizenship = Location.where(country: data[:person][:father][:citizenship]).last.id rescue nil
			 residential_country = Location.where(name: data[:person][:father][:residential_country]).last.id rescue nil

             unless citizenship.blank? || residential_country.blank?
             	location_found = true
             else
             	location_found = false
             end

	    end

    end

	return location_found
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

def pre_migration_check(params)

	  if params[:person][:created_by].blank?
        content = "#{params[:_id]},#{params[:person][:created_at]},#{params[:person][:created_by]},#{params[:person][:approved]},#{params[:person][:approved_by]}"
        write_log(@missing_doc_creator, content)
      end

      if ["Second Twin","Second Triplet","Third Triplet"].include? params[:person][:type_of_birth]
        if params[:person][:multiple_birth_id].blank?
         content = "#{params[:_id]},#{params[:person][:multiple_birth_id]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_multiple_birth_ids, content)
        end
      end

	  if params[:person][:type_of_birth].blank?
        content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
        write_log(@missing_birth_type, content)
      end

        status = get_record_status(params[:record_status],params[:request_status]).upcase.squish! rescue nil
	  if  status.blank?
        content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:record_status]},#{params[:request_status]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
        write_log(@missing_record_statuses, content)
      end

      if verify_location("Mother", "TA", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:mother][:home_ta]},#{params[:person][:mother][:home_district]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_tas, content)
      end

      if verify_location("Mother", "Village", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:mother][:home_village]},#{params[:person][:mother][:home_ta]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_villages, content)
      end

      if verify_location("Mother", "District", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:mother][:home_district]},#{params[:person][:mother][:residential_country]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_districts, content)
      end

      if verify_location("Mother", "Citizenship", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:mother][:citizenship]},#{params[:person][:mother][:residential_country]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_citizenships, content)
      end

      if verify_location("Father", "TA", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:father][:home_ta]},#{params[:person][:father][:home_district]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_tas, content)
      end

      if verify_location("Father", "Village", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:father][:home_village]},#{params[:person][:father][:home_ta]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_villages, content)
      end

      if verify_location("Father", "District", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:father][:home_district]},#{params[:person][:father][:residential_country]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_districts, content)
      end

      if verify_location("Father", "Citizenship", params) == false
      	 content = "#{params[:_id]},#{params[:person][:type_of_birth]},#{params[:person][:father][:citizenship]},#{params[:person][:father][:residential_country]},#{params[:person][:created_at]},#{params[:person][:created_by]}"
         write_log(@missing_citizenships, content)
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
	    #puts "Record for #{params[:person][:first_name]} #{params[:person][:middle_name]} #{params[:person][:last_name]} Created ............. "


      end

   rescue StandardError => e
          log_error(e.message, params)
   end

end

def mother_record_exist
   mothers = mother_records
   record = start
   precision = precision_level(mothers)
   puts "<<<< precision level: #{precision} <<<<<<<<<<<"
end

def precision_level(mothers, record)

	fnames = []
	lnames =[]
	home_villages =[]
	home_ta =[]
	home_districts =[]
	birthdates =[]
	citizenships =[]

	match_count = 0

	mothers.each do |x|

		fnames << x['first_name']
		lnames << x['last_name']
		home_villages << x['home_village']
        home_districts << x['home_district']
        birthdates << x['birthdate']
        citizenships << x['citizenship']
        home_ta << x['home_ta']

	end

    if fnames.include? record[:person][:mother][:first_name]
	   match_count = match_count + 1
	end
    if lnames.include? record[:person][:mother][:last_name]
	   match_count = match_count + 1
	end
	if home_villages.include? record[:person][:mother][:home_village]
	   match_count = match_count + 1
	end
	if home_ta.include? record[:person][:mother][:home_ta]
	   match_count = match_count + 1
	end
	if birthdates.include? record[:person][:mother][:birthdate]
	   match_count = match_count + 1
	end
	if home_districts.include? record[:person][:mother][:home_district]
	   match_count = match_count + 1
	end
	if citizenships.include? record[:person][:mother][:citizenship]
	   match_count = match_count + 1
	end

   if match_count == 7
    if !File.exists?(@suspected)
    	file = File.new(@suspected, 'w')
    else
    	File.open(@suspected, 'a')do |f|
           f.puts "match count: #{match_count} Name: #{record[:person][:mother][:first_name]}"
        end

    end
   end

   return match_count

end

def mother_records

	 mothers = []

	 records = PersonName.find_by_sql("SELECT P.person_id,first_name,last_name,birthdate,birthdate_estimated,home_village,home_ta,citizenship,home_district
	 	                               FROM person_name PN INNER JOIN person P ON P.person_id = PN.person_id
	 	                               INNER JOIN person_addresses PA ON PA.person_id = P.person_id WHERE PN.person_id
	 	                               IN (select person_b from person_relationship where person_relationship_type_id = 6)")

     (records || []).each do |rec|
         mothers << {'person_id' => rec.person_id,
         	        'first_name' => rec.first_name,
                   'last_name' => rec.last_name,
                   'birthdate' => rec.birthdate,
                   'birthdate_estimated' => rec.birthdate_estimated,
                   'home_village' => rec.home_village,
                   'home_ta' => rec.home_ta,
                   'citizenship'=> rec.citizenship,
                   'home_district' => rec.home_district }
     end

     return mothers
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



def transform_record(data)

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


    if data[:person][:type_of_birth]== 'Single'
=begin
    	if precision_level(mother_records, data) == 7
    		puts "registration type: #{data[:registration_type]} \n"
            puts "Saving partial record for #{data[:person][:first_name]} #{data[:person][:last_name]} ..."
    	    #save_partial_record(data, data[:person][:district_id_number])
    	else
=end
            #puts "Saving full record for #{data[:person][:first_name]} #{data[:person][:last_name]} ..."
            save_full_record(data,data[:person][:district_id_number])
#    	end
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

<<<<<<< HEAD

def test_method
	data ={}
	data = {person:{duplicate:"", is_exact_duplicate:"", relationship:"normal", last_name:"Ndala",
	        first_name:"Zimbota", middle_name:"", birthdate:"30/Oct/2015", birth_district:"Blantyre",
	        gender:"Male", place_of_birth:"Hospital", hospital_of_birth:"Mlambe Hospital",
	        birth_weight:"3.700", type_of_birth:"Single", parents_married_to_each_other:"Yes",
	        court_order_attached:"", parents_signed:"", national_serial_number:"00000214140",
	        district_id_number:"BT/0000125/2016", mother:{last_name:"Mkuwu", first_name:"Angella",
	        middle_name:"", birthdate:"22/Oct/1985", birthdate_estimated:"",
	        citizenship:"Malawian", residential_country:"Malawi", current_district:"Blantyre",
	        current_ta:"Machinjiri", current_village:"Machinjiri", home_district:"Mangochi",
	        home_ta:"Mponda", home_village:"Michesi"}, mode_of_delivery:"SVD",
	        level_of_education:"Secondary", father:{birthdate_estimated:"",
	        residential_country:"Malawi"}, informant:{last_name:"Mkuwu", first_name:"Angella",
	        middle_name:"", relationship_to_person:"Mother", current_district:"Blantyre",
	        current_ta:"Machinjiri", current_village:"Machinjiri", addressline1:"",
	        addressline2:"", phone_number:"0993853933"}, form_signed:"Yes",
	        acknowledgement_of_receipt_date:"2015-11-06 160456 -1000".to_date.strftime("%d/%b/%Y")},
	        home_address_same_as_physical:"Yes", gestation_at_birth:"37", number_of_prenatal_visits:"4",
	        month_prenatal_care_started:"3", number_of_children_born_alive_inclusive:"2",
	        number_of_children_born_still_alive:"2", same_address_with_mother:"",
	        informant_same_as_mother:"Yes", registration_type:"normal",
	        record_status:"PRINTED", _rev:"7-213580c4bcfdf268c901d5c3b11617c2",
	        _id:"0275f9967f6069e00bbf2d310871a2f8", request_status:"DISPATCHED",
	        biological_parents:"", foster_parents:"", parents_details_available:"",
	        copy_mother_name:"No", controller:"person", action:"create"}

    transform_record(data)
end

=======
>>>>>>> ab5bbd1f3422d6d1ad6a1fc4d40c35a00f023163

def build_client_record(current_pge, pge_size)

  data ={}

  records = Child.by__id.page(current_pge).per(pge_size)

  i = 0
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
					   national_serial_number: r[:national_serial_number],
					   parents_married_to_each_other: r[:parents_married_to_each_other],
					   date_of_marriage: r[:date_of_marriage],
					   court_order_attached: r[:court_order_attached],
					   created_at: r[:created_at],
					   created_by: r[:created_by],
					   updated_at: r[:updated_at],
					   parents_signed: "",
					   national_serial_number: r[:national_serial_number],
					   district_id_number: r[:district_id_number],
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
						foster_mother: {
								id_number: r[:id_number],
								first_name: r[:first_name],
								middle_name: r[:middle_name],
								last_name: r[:last_name],
								birthdate: r[:birthdate],
								birthdate_estimated: r[:birthdate_estimated],
								current_village: r[:current_village],
								current_ta: r[:current_ta],
								current_district: r[:current_district],
								home_village: r[:home_village],
								home_ta: r[:home_ta],
								home_district: r[:home_district],
								home_country: r[:home_country],
								citizenship: r[:citizenship],
								residential_country: r[:residential_country],
								foreigner_current_district: r[:foreigner_current_district],
								foreigner_current_village: r[:foreigner_current_village],
								foreigner_current_ta: r[:foreigner_current_ta],
								foreigner_home_district: r[:foreigner_home_district],
								foreigner_home_village: r[:foreigner_home_village],
								foreigner_home_ta: r[:foreigner_home_ta]
			        },
		     	  foster_father: {
							id_number: r[:id_number],
							first_name: r[:first_name],
							middle_name: r[:middle_name],
							last_name: r[:last_name],
							birthdate: r[:birthdate],
							birthdate_estimated: r[:birthdate_estimated],
							current_village: r[:current_village],
							current_ta: r[:current_ta],
							current_district: r[:current_district],
							home_village: r[:home_village],
							home_ta: r[:home_ta],
							home_district: r[:home_district],
							home_country: r[:home_country],
							citizenship: r[:citizenship],
							residential_country: r[:residential_country],
							foreigner_current_district: r[:foreigner_current_district],
							foreigner_current_village: r[:foreigner_current_village],
							foreigner_current_ta: r[:foreigner_current_ta],
							foreigner_home_district: r[:foreigner_home_district],
							foreigner_home_village: r[:foreigner_home_village],
							foreigner_home_ta: r[:foreigner_home_ta]
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
					   biological_parents: "",
					   foster_parents: "",
					   parents_details_available: "",
					   copy_mother_name: "No",
					   controller: "person",
					   action: "create"
					  }

			transform_record(data)
			i = i + 1
			if i % 100 == 0
				puts "Migrate #{i}"
			end


			#pre_migration_check(data)
   end
   records = nil
end


def initiate_migration

	total_records = Child.count
	page_size = 1000
	total_pages = (total_records / page_size) + (total_records % page_size)
	current_page = 1
	start_time = Time.now
	while (current_page < total_pages) do
        build_client_record(current_page, page_size)
        current_page = current_page + 1
        puts "Time taken #{(Time.now - start_time)/60} minites"
	end

   puts "\n"
	 puts "Completed migration of 1 of 3 batch of records! Please review the log files to verify.."
	 puts "\n"
end

initiate_migration
