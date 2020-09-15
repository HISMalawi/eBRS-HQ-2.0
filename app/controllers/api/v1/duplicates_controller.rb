class Api::V1::DuplicatesController < Api::V1::ApiController
  # GET /duplicates
  def index
    response = {
        'total' => DuplicateRecord.count
    }

    render :json => response
  end

  # GET /duplicates/:id
  def show; end

  # POST /duplicates
  def create; end

  # PUT /duplicates/:id
  def update; end

  # DELETE /duplicates/:id
  def destroy; end

end
