class Notification < ActiveRecord::Base
  include EbrsAttribute

  self.table_name = :notification
  self.primary_key = :notification_id

  def self.by_role(role_id)
    data = Notification.find_by_sql("
      SELECT n.notification_id, nt.name, nt.description, nt.role_id, prs.person_id, prs.status_id, prs.comments, s.name status, s.created_at FROM notification n
        INNER JOIN notification_types nt
          ON nt.notification_type_id = n.notification_type_id
        INNER JOIN person_record_statuses prs
          ON prs.person_record_status_id = n.person_record_status_id AND prs.voided = 0
        INNER JOIN statuses s
          ON s.status_id = prs.status_id
        WHERE n.seen = 0 AND nt.role_id = #{role_id}")

    data.as_json || []
  end
end
