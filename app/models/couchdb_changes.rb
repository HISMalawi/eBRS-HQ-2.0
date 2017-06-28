class CouchdbChange < ActiveRecord::Base
  self.table_name = :couchdb_changes
  self.primary_key = :couchdb_change_id
  include EbrsAttribute

end
