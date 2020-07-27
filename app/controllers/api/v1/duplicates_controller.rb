module Api
  module V1
    class DuplicatesController < ApiController
      # GET /duplicates
      def index
        duplicates_count = DuplicateRecord.count

        render json: {'Total Duplicates' => duplicates_count}
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
  end
end
