class Api::V1::BirthsController < Api::V1::ApiController
  # GET /births
  def index
    #   status_ids = Status.where(" name = 'HQ-CAN-PRINT' ").map(&:status_id)
    #
    #   PersonBirthDetail.find_by_sql(" SELECT * FROM person_birth_details d
    # INNER JOIN person_record_statuses prs ON prs.person_id = d.person_id
    #   AND (d.source_id IS NULL OR LENGTH(d.source_id) >  19)
    #   AND prs.status_id IN (#{status_ids.join(', ')})
    #   GROUP BY d.person_id").count

    response = {
        'total' => PersonBirthDetail.count,
        'registered' => PersonBirthDetail.count,
        'approved' => PersonBirthDetail.count
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

end
