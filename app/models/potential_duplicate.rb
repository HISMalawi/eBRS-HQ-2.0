class PotentialDuplicate < ActiveRecord::Base
    self.table_name = :potential_duplicates
    self.primary_key = :potential_duplicate_id
    belongs_to :person, foreign_key: "person_id"
    has_many :duplicate_records, foreign_key: "potential_duplicate_id"
    include EbrsAttribute
    def create_duplicate(id,created_at=Time.now)
    	DuplicateRecord.create(potential_duplicate_id: self.id, person_id: id , created_at: created_at)
    end
end
