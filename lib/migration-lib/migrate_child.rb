module MigrateChild
  require 'bean'
  require 'json'
  @rec_count = 0

  def self.new_child(params)
    core_person = CorePerson.create(
    person_type_id: PersonType.where(name: 'Client').last.id,
    created_at: params[:person][:created_at].to_date.strftime("%Y-%m-%d HH:MM:00"),
    updated_at: params[:person][:updated_at].to_date)
    #core_person.save
    @rec_count = @rec_count.to_i + 1
    person_id = CorePerson.first.person_id.to_i + @rec_count.to_i
    person = Person.create(
        :person_id          => core_person.id,
        :gender             => params[:person][:gender].first,
        :birthdate          => params[:person][:birthdate].to_date,
        :created_at         => params[:person][:created_at].to_date,
        :updated_at         => params[:person][:updated_at].to_date
     )

    PersonName.create(
        :person_id          => core_person.id,
        :first_name         => params[:person][:first_name],
        :middle_name        => params[:person][:middle_name],
        :last_name          => params[:person][:last_name],
        :created_at         => params[:person][:created_at].to_date,
        :updated_at         => params[:person][:updated_at].to_date
    )

    person
  end

  def self.search_citizenship(name)
      citizenship = Location.where(country: name).last
      if citizenship.blank?
        citizenship = Location.where(name: name).last
        if citizenship.blank?
                if name == "Moz"
                  citizenship = Location.where(name: "Mozambique").last
                elsif name.downcase.include?("united kingdom")
                  citizenship = Location.where(country: "British").last
                else
                  raise name.inspect
                end
             
        end
      end
      return citizenship
  end
  def self.workflow_init(person,params)

    status = nil
    is_record_a_duplicate = params[:person][:duplicate] rescue nil
    if is_record_a_duplicate.present?
        if params[:person][:is_exact_duplicate].present? && eval(params[:person][:is_exact_duplicate].to_s)
            status = PersonRecordStatus.new_record_state(person.id, 'DC-DUPLICATE')
        else
          if SETTINGS["application_mode"] == "FC"
            status = PersonRecordStatus.new_record_state(person.id, 'FC-POTENTIAL DUPLICATE')
          else
            status = PersonRecordStatus.new_record_state(person.id, 'DC-POTENTIAL DUPLICATE')
          end
        end
        potential_duplicate = PotentialDuplicate.create(person_id: person.id,created_at: (Time.now))
        if potential_duplicate.present?
             is_record_a_duplicate.split("|").each do |id|
                potential_duplicate.create_duplicate(id)
             end
        end
    else
       #status = PersonRecordStatus.new_record_state(person.id, 'DC-ACTIVE')
       status = PersonRecordStatus.new_record_state(person.id, params[:record_status])
    end

    return status
  end

  def self.log_error(error_msge, content)
    file_path = "#{Rails.root}/log/migration_error_log.txt"
    if !File.exists?(file_path)
           file = File.new(file_path, 'w')
    else

       File.open(file_path, 'a') do |f|
          f.puts "#{error_msge} >>>>>> {\"id\" : #{content['_id']}, \"rev\" : #{content['_rev']} }"

      end
    end

  end

  def self.save_ids(content)
     `echo #{content} >> #{Rails.root}/app/assets/data/person.csv`
  end

  def self.write_to_dump(filename,content)

     `echo -n '#{content}' >> #{Rails.root}/app/assets/data/migration_dumps/#{filename}`
  end

  def self.is_twin_or_triplet(type_of_birth)
    if type_of_birth == "Second Twin"
      return true
    elsif type_of_birth == "Second Triplet"
      return true
    elsif type_of_birth == "Third Triplet"
      return true
    else
      return false
    end
  end

  def self.log_error(error_msge, content)

    file_path = "#{Rails.root}/log/migration_error_log.txt"
    if !File.exists?(file_path)
           file = File.new(file_path, 'w')
    else

       File.open(file_path, 'a') do |f|
          f.puts "#{error_msge} >>>>>> #{content}"

      end
    end

 end
end
