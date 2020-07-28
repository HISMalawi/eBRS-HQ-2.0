module Api
  module V1
    class CertificatesController < ApplicationController
      # GET /certificates
      def index
        certificates_count = Certificate.count

        response = case params[:status]
                   when 'printed'
                     printed = Report.printed('2019-01-01','2019-01-29',[])
                     { 'Certificates printed' => printed }
                   when 'dispatched'
                     dispatched = Report.dispatched('2019-01-01','2019-01-29',[])
                     { 'Certificates dispatched' => dispatched }
                   else
                     # type code here
                     { 'Total certificates' => certificates_count}
                   end

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
