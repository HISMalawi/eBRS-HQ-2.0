require'migration-lib/migrate_child'
require 'migration-lib/migrate_mother'
require 'migration-lib/migrate_father'
require 'migration-lib/migrate_informant'
require "migration-lib/migrate_birth_details"
require 'migration-lib/person_service'
require "simple_elastic_search"
require 'json'

@missing_district_ids = "#{Rails.root}/app/assets/data/missing_district_ids.txt"
@loaded_data = "#{Rails.root}/app/assets/data/loaded_data.txt"
@file_path = "#{Rails.root}/app/assets/data/missing_district_id_num_docs.txt"
@multiple_birth_file = "#{Rails.root}/app/assets/data/multiple_birth_children.json"
@failed_to_save = "#{Rails.root}/app/assets/data/failed_to_save.txt"
@suspected = "#{Rails.root}/app/assets/data/suspected.txt"
@analysis = "#{Rails.root}/app/assets/data/analysis.txt"


User.current = User.last

Duplicate_attribute_type_id = PersonAttributeType.where(name: 'Duplicate Ben').first.id

password = CONFIG["crtkey"] rescue nil
$private_key = OpenSSL::PKey::RSA.new(File.read("#{Rails.root}/config/private.pem"), password)
$old_ben_type = PersonIdentifierType.where(name: 'Old Birth Entry Number').first.id
$old_brn_type = PersonIdentifierType.where(name: 'Old Birth Registration Number').first.id
$old_serial_type = PersonIdentifierType.where(name: 'Old Facility Number').first.id
$index = {}

if password.blank? || $private_key.blank?
  raise "Invalid Decryption Key".inspect
end

def write_log(file, content)

	if !File.exists?(file)
           file = File.new(file, 'w')
    else

       File.open(file, 'a') do |f|
          f.puts "#{content}"

      end


    end
end


def log_error(error_msge, content)

    file_path = "#{Rails.root}/log/migration_error_log.txt"
    if !File.exists?(file_path)
           file = File.new(file_path, 'w')
    else

       File.open(file_path, 'a') do |f|
          f.puts "#{error_msge} >>>>>> {\"id\" : #{content[:_id]}, \"rev\" : #{content[:_rev]} }"

      end
    end

 end

 def person_for_elastic_search(core_person,params)

      person = {}
      person["id"] = core_person.person_id
      person["first_name"]= params[:person][:first_name]
      person["last_name"] =  params[:person][:last_name]
      person["middle_name"] = params[:person][:middle_name]
      person["gender"] = params[:person][:gender]
      person["birthdate"]= params[:person][:birthdate].to_date.strftime('%Y-%m-%d')
      person["birthdate_estimated"] = params[:person][:birthdate_estimated]

      if MigrateChild.is_twin_or_triplet(params[:person][:type_of_birth].to_s)
         prev_child = Person.find(params[:person][:prev_child_id].to_i)
         if params[:relationship] == "opharned" || params[:relationship] == "adopted"
           mother = prev_child.adoptive_mother
         else
           mother = prev_child.mother
         end

         if mother.present?
            mother_name =  mother.person_names.first
         else
            mother_name = nil
         end

         person["mother_first_name"] = mother_name.first_name rescue ""
         person["mother_last_name"] =   mother_name.last_name rescue ""
         person["mother_middle_name"] =  mother_name.first_name rescue ""

         person["mother_home_district"] = Location.find(mother.addresses.last.home_district).name rescue nil
         person["mother_home_ta"] = Location.find(mother.addresses.last.home_ta).name rescue nil
         person["mother_home_village"] = Location.find(mother.addresses.last.home_village).name rescue nil

         person["mother_current_district"] = Location.find(mother.addresses.last.current_district).name rescue nil
         person["mother_current_ta"] = Location.find(mother.addresses.last.current_ta).name rescue nil
         person["mother_current_village"] = Location.find(mother.addresses.last.current_village).name rescue nil

         if params[:relationship] == "opharned" || params[:relationship] == "adopted"
           father = prev_child.adoptive_father
         else
           father = prev_child.father
         end

         if father.present?
            father_name =  father.person_names.first
         else
            father_name = nil
         end

         person["father_first_name"] = father_name.first_name rescue ""
         person["father_last_name"] =   father_name.last_name rescue ""
         person["father_middle_name"] = father_name.first_name rescue ""

         person["father_home_district"] = params[:person][:mother][:home_district] rescue nil
         person["father_home_ta"] = params[:person][:mother][:home_ta] rescue nil
         person["father_home_village"] = params[:person][:mother][:home_village] rescue nil

         person["father_current_district"] = params[:person][:mother][:home_district] rescue nil
         person["father_current_ta"] = params[:person][:mother][:home_ta] rescue nil
         person["father_current_village"] = params[:person][:mother][:home_village] rescue nil

         birth_details = prev_details = PersonBirthDetail.where(person_id: params[:person][:prev_child_id].to_i).first
         person["place_of_birth"] = Location.find(birth_details.place_of_birth).name
         person["district"] = Location.find(birth_details.district_of_birth).name
         person["nationality"]= Location.find(mother.addresses.first.citizenship).name rescue "Malawian"

      else

        person["place_of_birth"] = params[:person][:place_of_birth]
        person["district"] = params[:person][:birth_district]
        person["nationality"]=  params[:person][:mother][:citizenship]

        person["mother_first_name"]= params[:person][:mother][:first_name] rescue nil
        person["mother_last_name"] =  params[:person][:mother][:last_name] rescue nil
        person["mother_middle_name"] = params[:person][:mother][:middle_name] rescue nil

        person["mother_home_district"] = params[:person][:mother][:home_district] rescue nil
        person["mother_home_ta"] = params[:person][:mother][:home_ta] rescue nil
        person["mother_home_village"] = params[:person][:mother][:home_village] rescue nil

        person["mother_current_district"] = params[:person][:mother][:home_district] rescue nil
        person["mother_current_ta"] = params[:person][:mother][:home_ta] rescue nil
        person["mother_current_village"] = params[:person][:mother][:home_village] rescue nil

        person["father_first_name"]= params[:person][:father][:first_name] rescue nil
        person["father_last_name"] =  params[:person][:father][:last_name] rescue nil
        person["father_middle_name"] = params[:person][:father][:middle_name] rescue nil

        person["father_home_district"] = params[:person][:father][:home_district] rescue nil
        person["father_home_ta"] = params[:person][:father][:home_ta] rescue nil
        person["father_home_village"] = params[:person][:father][:home_village] rescue nil

        person["father_current_district"] = params[:person][:father][:home_district] rescue nil
        person["father_current_ta"] = params[:person][:father][:home_ta] rescue nil
        person["father_current_village"] = params[:person][:father][:home_village] rescue nil

      end
      return person
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

  params[:record_status] = get_record_status(params[:record_status],params[:request_status]).upcase.squish! rescue (raise params.inspect)
  person = PersonService.create_record(params)

  if !person.blank?
    #SimpleElasticSearch.add(person_for_elastic_search(person,params))
    assign_identifiers(person.person_id, params)
  end
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

def assign_identifiers(person_id, params)

    if !params[:person][:district_id_number].blank?
      PersonIdentifier.create(value: params[:person][:district_id_number], person_id: person_id, person_identifier_type_id: $old_ben_type)
    end

    if !params[:person][:national_serial_number].blank?
      PersonIdentifier.create(value: params[:person][:national_serial_number], person_id: person_id, person_identifier_type_id: $old_brn_type)
    end

    if !params[:person][:facility_serial_number].blank?
      PersonIdentifier.create(value: params[:person][:facility_serial_number], person_id: person_id, person_identifier_type_id: $old_serial_type)
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

		#================== Transforming the marriage date and or estimated marriage date iis partly known
		unless data[:person][:date_of_marriage].blank?
			   format_date(data[:person][:date_of_marriage])
    end

    if !data[:person][:district_id_number].blank?

      #create fixed BEN
      old_ben = data[:person][:district_id_number]
      code, inc, year = old_ben.split("/")
      $index[code] = {} if $index[code].blank?
      $index[code][year] = 0 if $index[code][year].blank?
      $index[code][year] += 1

      new_inc =  $index[code][year].to_s.rjust(8,'0')
      new_ben = "#{code}/#{new_inc}/#{year}"

      #data[:person][:new_district_id_number] = new_ben
    end

    if data[:person][:type_of_birth]== 'Single'
      save_full_record(data,data[:person][:district_id_number])
    else

    end
end

def format_date(date)
	unless date.blank?
		if date.split("/")[0]  == "?"
			 estimated_date = date.split("/")
			 estimated_date[0] = 15
			 date = estimated_date.join("/")
		end
		if date.split("/")[1]  == "?"
			 estimated_date = date.split("/")
			 estimated_date[1] = 7
			 date = estimated_date.join("/")
		end
	 end
	return date
end

def get_record_status(rec_status, req_status)


 status = {"DC OPEN" => {'ACTIVE' =>'DC-ACTIVE',
      							'IN-COMPLETE' =>'DC-INCOMPLETE',
      							'COMPLETE' =>'DC-COMPLETE',
      							'DUPLICATE' =>'DC-DUPLICATE',
      							'POTENTIAL DUPLICATE' =>'DC-POTENTIAL DUPLICATE',
      							'GRANTED' =>'DC-GRANTED',
      							'PENDING' => 'DC-PENDING',
      							'CAN-REPRINT' => 'HQ-CAN-RE-PRINT',
                    'CAN RE_PRINT' => 'HQ-CAN-RE-PRINT',
      							'REJECTED' =>'DC-REJECTED'},
		"POTENTIAL DUPLICATE" => {'ACTIVE' =>'FC-POTENTIAL DUPLICATE'},
		"POTENTIAL-DUPLICATE" =>{'VOIDED'=>'DC-VOIDED'},
		"VOIDED" =>{'CLOSED' =>'DC-VOIDED',
					'CLOSED' =>'HQ-VOIDED'},
		"PRINTED" =>{'CLOSED' =>'HQ-PRINTED',
					'DISPATCHED' =>'HQ-DISPATCHED'},
		"HQ-PRINTED" =>{'CLOSED' =>'HQ-PRINTED'},
		"HQ-DISPATCHED" =>{'DISPATCHED' =>'HQ-DISPATCHED'},
		"HQ-CAN-PRINT" =>{'CAN PRINT' =>'HQ-CAN-RE-PRINT'},
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

   s = status[rec_status][req_status] rescue (raise "rec:  #{rec_status}   ----   req:   #{req_status}    NOT FOUND!".inspect)
   return s
end

def decrypt(value)
    string = $private_key.private_decrypt(Base64.decode64(value)) rescue nil

    return value if string.nil?

    return string

end

def build_client_record(records, n)

    data ={}

    ActiveRecord::Base.transaction do
    i = 0
    (records || []).each do |doc|
      r = doc["doc"].with_indifferent_access
      data = { person: {duplicate: "", is_exact_duplicate: "",
               relationship: (r[:relationship].blank? ? 'normal' : r[:relationship]),
               last_name: decrypt(r[:last_name]),
               first_name: decrypt(r[:first_name]),
               middle_name: decrypt(r[:middle_name]),
               birthdate: r[:birthdate],
               birth_district: r[:birth_district],
               gender: r[:gender],
               place_of_birth: r[:place_of_birth],
               hospital_of_birth: r[:hospital_of_birth],
               birth_weight: r[:birth_weight],
               type_of_birth: r[:type_of_birth],
               parents_married_to_each_other: r[:parents_married_to_each_other],
               date_of_marriage: r[:date_of_marriage],
               court_order_attached: r[:court_order_attached],
               created_at: r[:created_at],
               created_by: r[:created_by],
               updated_at: r[:updated_at],
               parents_signed: "",
               district_id_number: r[:district_id_number],
               national_serial_number: r[:national_serial_number],
               facility_serial_number: r[:facility_serial_number],
               mother: {},
               father:{},
               npid: decrypt(r[:npid]),
               mode_of_delivery: r[:mode_of_delivery],
               level_of_education: r[:level_of_education],
               informant: {},
              foster_mother: {},
              foster_father: {},
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
               registration_type: (r[:relationship].blank? ? 'normal' : r[:relationship]),
               record_status: decrypt(r[:record_status]),
               _rev: r[:_rev],
               _id: r[:_id],
               request_status: decrypt(r[:request_status]),
               biological_parents: "",
               foster_parents: "",
               parents_details_available: "",
               copy_mother_name: "No",
               controller: "person",
               action: "create",
               district_code: (r[:district_code] rescue nil),
               facility_code: (r[:facility_code] rescue nil)
              }

              if !r[:mother].blank?
                data[:person][:mother] = {
                    last_name: decrypt(r[:mother][:last_name]) ,
                    first_name: decrypt(r[:mother][:first_name]),
                    middle_name: decrypt(r[:mother][:middle_name]),
                    birthdate: r[:mother][:birthdate],
                    birthdate_estimated: r[:mother][:birthdate_estimated],
                    citizenship: r[:mother][:citizenship],
                    residential_country: r[:mother][:residential_country],
                    current_district: (r[:mother][:current_district]  rescue nil),
                    current_ta: (r[:mother][:current_ta]  rescue nil),
                    current_village: (r[:mother][:current_village]  rescue nil),
                    home_district: (r[:mother][:home_district]  rescue nil),
                    home_ta: (r[:mother][:home_ta]  rescue nil),
                    home_village: (r[:mother][:home_village]  rescue nil),
                    foreigner_current_district: (r[:mother][:foreigner_current_district] rescue nil),
                    foreigner_current_village: (r[:mother][:foreigner_current_village] rescue nil),
                    foreigner_current_ta: (r[:mother][:foreigner_current_ta] rescue nil),
                    foreigner_home_district: (r[:mother][:foreigner_home_district] rescue nil),
                    foreigner_home_village: (r[:mother][:foreigner_home_village] rescue nil),
                    foreigner_home_ta: (r[:mother][:foreigner_home_ta] rescue nil)
                }
              end

              if !r[:father].blank?
                data[:person][:father] =  {
                    last_name: decrypt(r[:father][:last_name]),
                    first_name: decrypt(r[:father][:first_name]),
                    middle_name: decrypt(r[:father][:middle_name]),
                    birthdate: r[:father][:birthdate],
                    birthdate_estimated: r[:father][:birthdate_estimated],
                    citizenship: r[:father][:citizenship],
                    residential_country: r[:father][:residential_country],
                    current_district: (r[:father][:current_district]  rescue nil),
                    current_ta: (r[:father][:current_ta]  rescue nil),
                    current_village: (r[:father][:current_village]  rescue nil),
                    home_district: (r[:father][:home_district]  rescue nil),
                    home_ta: (r[:father][:home_ta]  rescue nil),
                    home_village: (r[:father][:home_village]  rescue nil),
                    foreigner_current_district: (r[:father][:foreigner_current_district] rescue nil),
                    foreigner_current_village: (r[:father][:foreigner_current_village] rescue nil),
                    foreigner_current_ta: (r[:father][:foreigner_current_ta] rescue nil),
                    foreigner_home_district: (r[:father][:foreigner_home_district] rescue nil),
                    foreigner_home_village: (r[:father][:foreigner_home_village] rescue nil),
                    foreigner_home_ta: (r[:father][:foreigner_home_ta] rescue nil)
                }
              end

              if !r[:informant].blank?
                data[:person][:informant] =  {
                    last_name: decrypt(r[:informant][:last_name]),
                    first_name: decrypt(r[:informant][:first_name]),
                    middle_name: decrypt(r[:informant][:middle_name]),
                    relationship_to_person: r[:informant][:relationship_to_child],
                    current_district: r[:informant][:current_district],
                    current_ta: r[:informant][:current_ta],
                    current_village: r[:informant][:current_village],
                    addressline1: r[:informant][:addressline1],
                    addressline2: r[:informant][:addressline2],
                    phone_number: r[:informant][:phone_number]
                }
              end

              if !r[:foster_mother].blank?
                data[:person][:foster_mother] ={
                    id_number: (r[:foster_mother][:id_number] rescue nil),
                    first_name: decrypt((r[:foster_mother][:first_name] rescue nil)),
                    middle_name: decrypt((r[:foster_mother][:middle_name] rescue nil)),
                    last_name: decrypt((r[:foster_mother][:last_name] rescue nil)),
                    birthdate: (r[:foster_mother][:birthdate] rescue nil),
                    birthdate_estimated: (r[:foster_mother][:birthdate_estimated] rescue nil),
                    current_village: (r[:foster_mother][:current_village] rescue nil),
                    current_ta: (r[:foster_mother][:current_ta] rescue nil),
                    current_district: (r[:foster_mother][:current_district] rescue nil),
                    home_village: (r[:foster_mother][:home_village] rescue nil),
                    home_ta: (r[:foster_mother][:home_ta] rescue nil),
                    home_district: (r[:foster_mother][:home_district] rescue nil),
                    home_country: (r[:foster_mother][:home_country] rescue nil),
                    citizenship: (r[:foster_mother][:citizenship] rescue nil),
                    residential_country: (r[:foster_mother][:residential_country] rescue nil),
                    foreigner_current_district: (r[:foster_mother][:foreigner_current_district] rescue nil),
                    foreigner_current_village: (r[:foster_mother][:foreigner_current_village] rescue nil),
                    foreigner_current_ta: (r[:foster_mother][:foreigner_current_ta] rescue nil),
                    foreigner_home_district: (r[:foster_mother][:foreigner_home_district] rescue nil),
                    foreigner_home_village: (r[:foster_mother][:foreigner_home_village] rescue nil),
                    foreigner_home_ta: (r[:foster_mother][:foreigner_home_ta] rescue nil)
                }
              end

              if !r[:foster_father].blank?
                data[:person][:foster_father] =   {
                    id_number: (r[:foster_father][:id_number] rescue nil),
                    first_name: decrypt((r[:foster_father][:first_name] rescue nil)),
                    middle_name: decrypt((r[:foster_father][:middle_name] rescue nil)),
                    last_name: decrypt((r[:foster_father][:last_name] rescue nil)),
                    birthdate: (r[:foster_father][:birthdate] rescue nil),
                    birthdate_estimated: (r[:foster_father][:birthdate_estimated] rescue nil),
                    current_village: (r[:foster_father][:current_village] rescue nil),
                    current_ta: (r[:foster_father][:current_ta] rescue nil),
                    current_district: (r[:foster_father][:current_district] rescue nil),
                    home_village: (r[:foster_father][:home_village] rescue nil),
                    home_ta: (r[:foster_father][:home_ta] rescue nil),
                    home_district: (r[:foster_father][:home_district] rescue nil),
                    home_country: (r[:foster_father][:home_country] rescue nil),
                    citizenship: (r[:foster_father][:citizenship] rescue nil),
                    residential_country: (r[:foster_father][:residential_country] rescue nil),
                    foreigner_current_district: (r[:foster_father][:foreigner_current_district] rescue nil),
                    foreigner_current_village: (r[:foster_father][:foreigner_current_village] rescue nil),
                    foreigner_current_ta: (r[:foster_father][:foreigner_current_ta] rescue nil),
                    foreigner_home_district: (r[:foster_father][:foreigner_home_district] rescue nil),
                    foreigner_home_village: (r[:foster_father][:foreigner_home_village] rescue nil),
                    foreigner_home_ta: (r[:foster_father][:foreigner_home_ta] rescue nil)
                }
              end

         transform_record(data)
        i = i + 1
        if i % 100 == 0
          puts n + i
        end
     end
     records = nil
    end

end


def initiate_migration(records)

	total_records = records.count
  puts "\n"
	puts "Completed migration of 1 of 3 batch of records! Please review the log files to verify.."
	puts "\n"
end

configs = YAML.load_file("#{Rails.root}/config/couchdb.yml")[Rails.env]

#`curl -X GET http://root:password@localhost:5984/ebrsmig/_design/Child/_view/all?include_docs=true >> data.json`
records = Oj.load File.read("#{Rails.root}/data.json")
records['rows'] = records['rows'].sort_by { |r| (r[:approved_at].to_datetime rescue nil)}

records['rows'].each_slice(1000).to_a.each_with_index do |block, i|
  puts "#{Time.now.to_s(:db)}"
  start = i*1000
  build_client_record(block, start)
  puts "#{Time.now.to_s(:db)}"
end
