class NotificationType < ActiveRecord::Base
  include EbrsMetadata

  self.table_name = :notification_types
  self.primary_key = :notification_type_id 
end
