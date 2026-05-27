module Analytics
  class AbcCurveService < BaseService
    def call
      total_revenue = product_sales.sum { |data| data.fetch(:revenue) }
      cumulative = BigDecimal("0")

      {
        period: period_payload,
        total_revenue: total_revenue.to_s,
        products: product_sales.sort_by { |data| -data.fetch(:revenue) }.map do |data|
          participation = total_revenue.positive? ? (data.fetch(:revenue) / total_revenue * 100) : BigDecimal("0")
          cumulative += participation

          product_payload(data).merge(
            participation_percentage: participation.to_s,
            cumulative_percentage: cumulative.to_s,
            abc_class: abc_class(cumulative)
          )
        end
      }
    end

    private

    def abc_class(cumulative_percentage)
      return "A" if cumulative_percentage <= 80
      return "B" if cumulative_percentage <= 95

      "C"
    end
  end
end
