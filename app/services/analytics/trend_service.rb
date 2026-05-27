module Analytics
  class TrendService < BaseService
    VALID_GRANULARITIES = %w[day week month].freeze

    def call
      raise ArgumentError, "granularity is invalid" unless VALID_GRANULARITIES.include?(granularity)

      {
        period: period_payload,
        granularity: granularity,
        points: grouped_sales.map do |label, items|
          revenue = items.sum(&:total_price)
          quantity = items.sum(&:quantity)

          {
            period: label,
            total_revenue: revenue.to_s,
            quantity_sold: quantity
          }
        end
      }
    end

    private

    def granularity
      params.fetch(:granularity, "day").presence || "day"
    end

    def grouped_sales
      sale_items.group_by { |item| label_for(item.sale.sold_at) }.sort.to_h
    end

    def label_for(time)
      case granularity
      when "day"
        time.to_date.iso8601
      when "week"
        time.to_date.beginning_of_week.iso8601
      when "month"
        time.strftime("%Y-%m")
      end
    end
  end
end
