module Api
  module V1
    class ReportsController < Auth::BaseController
      before_action :authenticate_user_from_token!

      def overview
        render_report(Reports::OverviewService)
      end

      def statistics
        render_report(Reports::SalesStatisticsService)
      end

      def stock
        render_report(Reports::StockReportService)
      end

      def financial
        render_report(Reports::FinancialReportService)
      end

      private

      def render_report(service)
        authorize :report, :show?

        render_success(service.call(report_params))
      rescue ArgumentError => error
        render_error(error.message, status: :unprocessable_entity)
      end

      def report_params
        params.permit(:start_date, :end_date, :period)
      end
    end
  end
end
