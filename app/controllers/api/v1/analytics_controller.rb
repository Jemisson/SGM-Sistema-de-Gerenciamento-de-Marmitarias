module Api
  module V1
    class AnalyticsController < Auth::BaseController
      before_action :authenticate_user_from_token!

      def abc
        render_analytics(Analytics::AbcCurveService)
      end

      def profitability
        render_analytics(Analytics::ProfitabilityService)
      end

      def trends
        render_analytics(Analytics::TrendService)
      end

      def product_performance
        render_analytics(Analytics::ProductPerformanceService)
      end

      def ingredient_consumption
        render_analytics(Analytics::IngredientConsumptionService)
      end

      private

      def render_analytics(service)
        authorize :analytics, :show?

        render_success(service.call(analytics_params))
      rescue ArgumentError => error
        render_error(error.message, status: :unprocessable_entity)
      end

      def analytics_params
        params.permit(:start_date, :end_date, :product_id, :category_id, :granularity)
      end
    end
  end
end
