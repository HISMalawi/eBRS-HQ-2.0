module Api
  module V1
    class ApiController < ActionController::API
      #before_action :check_basic_auth
      #skip_before_action :verify_authenticity_token
      # skip_before_filter :api_v1_birth_path, :api_v1_birth_url, :api_v1_births_path, :api_v1_births_url

      private

      def check_basic_auth
        unless request.authorization.present?
          head :unauthorized
          return
        end

        authenticate_or_request_with_http_basic do |username, password|
          username == 'admin250' && password == 'adminebrs'
          # user = User.get_active_user(username)
          # if user && user.password_matches?(password)
          #   # login! user
          #   @current_user = user
          # else
          #   head :unauthorized
          # end
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
