module Analytics
  class ProfitabilityService < BaseService
    def call
      {
        period: period_payload,
        products: product_sales.sort_by { |data| -data.fetch(:gross_profit) }.map do |data|
          revenue = data.fetch(:revenue)
          margin = revenue.positive? ? (data.fetch(:gross_profit) / revenue * 100) : BigDecimal("0")

          product_payload(data).merge(
            gross_margin_percentage: margin.to_s,
            average_sale_price: average_sale_price(data).to_s,
            estimated_unit_cost: estimated_unit_cost(data).to_s
          )
        end
      }
    end

    private

    def average_sale_price(data)
      return BigDecimal("0") if data.fetch(:quantity_sold).zero?

      data.fetch(:revenue) / data.fetch(:quantity_sold)
    end

    def estimated_unit_cost(data)
      return BigDecimal("0") if data.fetch(:quantity_sold).zero?

      data.fetch(:estimated_cost) / data.fetch(:quantity_sold)
    end
  end
end
