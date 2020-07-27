module Api
  module V1
    class CertificatesController < ApplicationController
      # GET /certificates
      def index
        certificates_count = Certificate.count

        render json: {'Total Certificates' => certificates_count}
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
