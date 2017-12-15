class Notification < ActiveRecord::Base
  include EbrsAttribute

  self.table_name = :notification
  self.primary_key = :notification_id  
end
