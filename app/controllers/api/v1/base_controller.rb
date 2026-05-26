module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      respond_to :json

      before_action :set_default_response_format

      protected

      def admin_user?
        current_user&.admin?
      end

      def manager_user?
        current_user&.manager?
      end

      def cashier_user?
        current_user&.cashier?
      end

      private

      def set_default_response_format
        request.format = :json
      end
    end
  end
end
