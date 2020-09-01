class Api::V1::BirthsController < Api::V1::ApiController
  # GET /births
  def index
    # TODO: Make dynamic once filter feature is added in CRVS Visio
    start_date = '01-01-2019'
    end_date = '20-01-2019'
    #   status_ids = Status.where(" name = 'HQ-CAN-PRINT' ").map(&:status_id)
    #
    #   PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
    # INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
    #   AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
    #   AND prs.status_id IN (#{status_ids.join(', ')})
    #   GROUP BY d.person_id").count

    response = {
        'reported' => reported,
        'registered' => PersonBirthDetail.where.not(date_registered: [nil,'']).count,
        'approved' => approved
    }

    render :json => response
  end

  # GET /births/:id
  def show; end

  # POST /births
  def create; end

  # PUT /births/:id
  def update; end

  # DELETE /births/:id
  def destroy; end

  private

  def reported
    query = "select count(*) as total from person_birth_details;"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

  def registered
    query = "SELECT count(*) as total FROM person_birth_details WHERE date_registered IS NOT NULL"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

  def approved
    query = "SELECT count(*) as total FROM person_birth_details d
    INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
    WHERE (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
    AND prs.status_id IN (select status_id FROM statuses where name = 'HQ-CAN-PRINT');"

    ActiveRecord::Base.connection.select_all(query).as_json.last['total'] rescue 0
  end

end
