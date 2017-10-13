class PersonName < ActiveRecord::Base
    self.table_name = :person_name
    self.primary_key = :person_name_id
    include EbrsAttribute
    default_scope { where(voided: 0) }

    belongs_to :person
    belongs_to :core_person
    has_one :person_name_code

    before_create :check_length

  def check_length
    self.first_name = '@@@@@' if self.first_name.length > 100
    self.middle_name = '@@@@@' if self.middle_name.length > 100
    self.last_name = '@@@@@' if self.last_name.length > 100
  end
end
