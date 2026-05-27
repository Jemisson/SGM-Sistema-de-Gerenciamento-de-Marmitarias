module Analytics
  class ProductPerformanceService < BaseService
    def call
      sorted = product_sales.sort_by { |data| -data.fetch(:quantity_sold) }

      {
        period: period_payload,
        most_sold_products: sorted.first(5).map { |data| product_payload(data) },
        least_sold_products: sorted.reverse.first(5).map { |data| product_payload(data) }
      }
    end
  end
end
