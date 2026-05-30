module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 100

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

      def paginate(scope)
        scope.page(pagination_page).per(pagination_per_page)
      end

      def pagination_meta(collection)
        {
          page: collection.current_page,
          per_page: collection.limit_value,
          total_count: collection.total_count,
          total_pages: collection.total_pages
        }
      end

      private

      def set_default_response_format
        request.format = :json
      end

      def pagination_page
        [request.query_parameters.fetch(:page, 1).to_i, 1].max
      end

      def pagination_per_page
        requested_per_page = request.query_parameters.fetch(:per_page, DEFAULT_PER_PAGE).to_i

        requested_per_page.clamp(1, MAX_PER_PAGE)
      end
    end
  end
end
