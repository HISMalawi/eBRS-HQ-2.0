class PersonName < ActiveRecord::Base
    self.table_name = :person_name
    self.primary_key = :person_name_id
    include EbrsAttribute
    #default_scope { where(voided: 0) }

    belongs_to :person
    belongs_to :core_person
    has_one :person_name_code

  after_initialize :strip_special_chars

  def strip_special_chars
	  self.first_name = "" if !self.first_name.blank? && self.first_name.match("@")
    self.last_name = "" if !self.last_name.blank? && self.last_name.match("@")
    self.middle_name = "" if !self.middle_name.blank? && self.middle_name.match("@")
  end
end
