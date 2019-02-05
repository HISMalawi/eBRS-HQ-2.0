class Certificate < ActiveRecord::Base
    self.table_name = :certificate
    self.primary_key = :id
    before_save :check_date_audits

    def check_date_audits
      if !self.person_id.blank?
        print_ids = Status.where(" name IN ('HQ-PRINTED', 'DC-PRINTED') ").map(&:status_id)
        dispatch_ids = Status.where(" name = 'HQ-DISPATCHED' ").map(&:status_id)

        prints      = PersonRecordStatus.where(" person_id = #{self.person_id} AND status_id IN (#{print_ids.join(',')}) ")
        dispatches  = PersonRecordStatus.where(" person_id = #{self.person_id} AND status_id IN (#{dispatch_ids.join(',')}) ")

        print_count     = prints.count
        print_count     = 1 if print_count == 0
        date_printed    = prints.collect{|s| s.created_at}.max
        date_dispatched = dispatches.collect{|s| s.created_at}.max

        self.print_count      = print_count     if self.print_count.blank?
        self.date_printed     = date_printed    if self.date_printed.blank?
        self.date_dispatched  = date_dispatched if self.date_dispatched.blank?
      end
    end

end
