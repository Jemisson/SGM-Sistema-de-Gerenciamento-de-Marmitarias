module Reports
  class SalesStatisticsService
    include SalesMetrics

    def self.call(...)
      new(...).call
    end

    def initialize(params = {})
      @period = PeriodRange.call(params)
    end

    def call
      {
        period: period_payload,
        total_sold: confirmed_sales.count,
        total_revenue: total_revenue.to_s,
        average_ticket: average_ticket.to_s,
        sales_by_payment_method: sales_by_payment_method,
        sales_by_product: top_products(nil)
      }
    end

    private

    attr_reader :period

    def sales_by_payment_method
      confirmed_sales.group(:payment_method).sum(:total_amount).transform_values(&:to_s)
    end

    def period_payload
      {
        start_date: period.start_date.iso8601,
        end_date: period.end_date.iso8601
      }
    end
  end
end
