class Person < ActiveRecord::Base
  self.table_name = :person
  self.primary_key = :person_id
  belongs_to :core_person, foreign_key: "person_id"
  has_many :person_names
  has_many :person_addresses

  include EbrsAttribute

  def addresses
    PersonAddress.where(person_id: self.id)
  end

  def mother
    result = nil
    relationship_type = PersonRelationType.find_by_name("Mother")

    relationship = PersonRelationship.where(:person_a => self.person_id, :person_relationship_type_id => relationship_type.id).last
    unless relationship.blank?
      result = Person.where(:person_id => relationship.person_b).last
    end

    result
  end

  def father
    result = nil
    relationship_type = PersonRelationType.find_by_name("Father")

    relationship = PersonRelationship.where(:person_a => self.person_id, :person_relationship_type_id => relationship_type.id).last
    unless relationship.blank?
      result = Person.where(:person_id => relationship.person_b).last
    end

    result
  end

  def informant
    result = nil
    relationship_type = PersonRelationType.find_by_name("Informant")

    relationship = PersonRelationship.where(:person_a => self.person_id, :person_relationship_type_id => relationship_type.id).last
    unless relationship.blank?
      result = Person.where(:person_id => relationship.person_b).last
    end

    result
  end

end
