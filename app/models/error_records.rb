class ErrorRecords < ActiveRecord::Base
    self.table_name = :error_records
    self.primary_key = :id

  def self.active_issues
    ErrorRecords.where(" passed = 0 AND LENGTH(person_id) > 5 AND person_id LIKE '1%' ").order("created_at DESC")
  end
end
