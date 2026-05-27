module Reports
  module SalesMetrics
    private

    def confirmed_sales
      Sale.confirmed.where(sold_at: period.start_date..period.end_date)
    end

    def total_revenue
      confirmed_sales.sum(:total_amount)
    end

    def average_ticket
      count = confirmed_sales.count
      return BigDecimal("0") if count.zero?

      total_revenue / count
    end

    def top_products(limit = 5)
      scope = SaleItem.joins(:sale, :product)
              .where(sales: { status: Sale.statuses[:confirmed], sold_at: period.start_date..period.end_date })
              .group("products.id", "products.code", "products.name")
              .select(
                "products.id AS product_id",
                "products.code AS product_code",
                "products.name AS product_name",
                "SUM(sale_items.quantity) AS quantity_sold",
                "SUM(sale_items.total_price) AS revenue"
              )
              .order(Arel.sql("SUM(sale_items.quantity) DESC"))
      scope = scope.limit(limit) if limit

      scope.map do |row|
        {
          product_id: row.product_id,
          code: row.product_code,
          name: row.product_name,
          quantity_sold: row.quantity_sold.to_i,
          revenue: row.revenue.to_s
        }
      end
    end

    def gross_profit
      total_revenue - sale_consumption_cost
    end

    def sale_consumption_cost
      StockMovement.sale_consumption
                   .joins(:ingredient)
                   .where(occurred_at: period.start_date..period.end_date)
                   .sum("stock_movements.quantity * COALESCE(ingredients.purchase_price, 0)")
    end
  end
end
