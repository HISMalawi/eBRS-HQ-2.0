module Api
  module V1
    class CertificatesController < ApplicationController
      # GET /certificates
      def index

        response = {
            'total' => Certificate.count,
            'printed' => Certificate.where('date_printed IS NOT NULL').count,
            'dispatched' => Certificate.where('date_dispatched IS NOT NULL').count
        }

        render :json => response
      end

      # GET /certificates/:id
      def show; end

      # POST /certificates
      def create; end

      # PUT /certificates/:id
      def update; end

      # DELETE /certificates/:id
      def destroy; end

    end
  end
end
