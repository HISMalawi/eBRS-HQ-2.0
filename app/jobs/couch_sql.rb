class CouchSQL
  include SuckerPunch::Job
  workers 1

  def perform()
    begin
      load "#{Rails.root}/bin/couch-mysql.rb"
      SuckerPunch.logger.info "Couch >> SQL"
    rescue => e
      SuckerPunch.logger.info "=========Error #{e.to_s}"
      CouchSQL.perform_in(5)
    end

    CouchSQL.perform_in(5)
  end


end

