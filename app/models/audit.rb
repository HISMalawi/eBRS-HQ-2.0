require 'couchrest_model'

class Audit	< CouchRest::Model::Base
  use_database "audit"
 
  property :record_id, String # Certificate/Child id
  property :audit_type, String # Quality Control | Reprint | Audit | Deduplication | Incomplete Record | DC Record Rejection | HQ Record Rejection | HQ Void | HQ Re-Open | Potential Duplicate
  property :level, String # Child | User
  property :reason, String
  property :user_id, String # User id
  property :site_id, String
  property :site_type, String  #FACILITY, DC, HQ
  property :change_log, [], :default => []
  property :voided, TrueClass, :default => false

  timestamps!

  design do
    view :by_record_id
  end
end
