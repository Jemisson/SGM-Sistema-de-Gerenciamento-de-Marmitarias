module Reports
  class OverviewService
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
        total_revenue: total_revenue.to_s,
        average_ticket: average_ticket.to_s,
        gross_profit: gross_profit.to_s,
        stock_items_count: Ingredient.active.count,
        top_products: top_products
      }
    end

    private

    attr_reader :period

    def period_payload
      {
        start_date: period.start_date.iso8601,
        end_date: period.end_date.iso8601
      }
    end
  end
end
