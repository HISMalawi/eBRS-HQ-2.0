class PersonName < ActiveRecord::Base
    self.table_name = :person_name
    self.primary_key = :person_name_id
    include EbrsAttribute
    default_scope { where(voided: 0) }

    belongs_to :person
    belongs_to :core_person
    has_one :person_name_code

<<<<<<< HEAD
    before_create :check_length, :check_special_chars

  def check_length
    self.first_name = '@@@@@' if (!self.first_name.blank? && self.first_name.length > 100 rescue true)
    self.middle_name = '@@@@@' if (!self.middle_name.blank? && self.middle_name.length > 100 rescue true)
    self.last_name = '@@@@@' if (!self.last_name.blank? && self.last_name.length > 100 rescue true)
  end
  def check_special_chars
      special = "?<>?[]}{=)(*&^%$#`~{}"
      regex = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
      self.first_name = "@@@@@" if (self.first_name =~ regex).to_i > 0
      self.last_name = "@@@@@" if (self.last_name =~ regex).to_i > 0
      self.middle_name = "@@@@@" if (self.middle_name =~ regex).to_i > 0
=======
  after_initialize :strip_special_chars

  def strip_special_chars
    self.first_name = "" if !self.first_name && self.first_name.match("@")
    self.last_name = "" if !self.last_name.blank? && self.last_name.match("@")
    self.middle_name = "" if !self.middle_name.blank? && self.middle_name.match("@")
>>>>>>> 4bd8ddc20931d6baca6990c9acd6300a43c372a6
  end
end
