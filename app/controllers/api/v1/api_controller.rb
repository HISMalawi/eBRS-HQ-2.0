module Api
  module V1
    class ApiController < ApplicationController
      #before_action :check_basic_auth
      #skip_before_action :verify_authenticity_token

      private

      def check_basic_auth
        unless request.authorization.present?
          head :unauthorized
          return
        end

        authenticate_with_http_basic do |username, password|
          user = User.get_active_user(username)
          if user && user.password_matches?(password)
            login! user
            @current_user = user
          else
            head :unauthorized
          end
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
