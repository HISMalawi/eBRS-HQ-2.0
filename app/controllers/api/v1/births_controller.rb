module Api
  module V1
    class BirthsController < ApplicationController
      # GET /births
      def index

        response = case params[:state]
                   when 'reported'
                     births_reported = Report.reported('2019-01-01','2019-01-29',[])
                     { 'Births reported' => births_reported}
                   when 'approved'
                     births_approved = Report.approved_by_dm('2019-01-01','2019-01-29',[])
                     { 'Births reported' => births_approved}
                   else
                     total_births = PersonBirthDetail.count
                     { 'Total births' => total_births}
                   end

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
  end
end
