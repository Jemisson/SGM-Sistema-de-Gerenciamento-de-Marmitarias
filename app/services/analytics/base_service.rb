module Analytics
  class BaseService
    def self.call(...)
      new(...).call
    end

    def initialize(params = {})
      @params = params.to_h.symbolize_keys
      @period = build_period
    end

    private

    attr_reader :params, :period

    def build_period
      if params[:start_date].present? || params[:end_date].present?
        Reports::PeriodRange.call(
          period: "custom",
          start_date: params[:start_date],
          end_date: params[:end_date]
        )
      else
        Reports::PeriodRange.call(period: "month")
      end
    end

    def period_payload
      {
        start_date: period.start_date.iso8601,
        end_date: period.end_date.iso8601
      }
    end

    def sale_items_scope
      scope = SaleItem.joins(:sale, product: :category)
                      .includes(product: { recipe: { recipe_items: :ingredient } })
                      .where(sales: { status: Sale.statuses[:confirmed], sold_at: period.start_date..period.end_date })
      scope = scope.where(product_id: params[:product_id]) if params[:product_id].present?
      scope = scope.where(products: { category_id: params[:category_id] }) if params[:category_id].present?
      scope
    end

    def sale_items
      @sale_items ||= sale_items_scope.to_a
    end

    def product_sales
      sale_items.group_by(&:product).map do |product, items|
        quantity_sold = items.sum(&:quantity)
        revenue = items.sum(&:total_price)
        cost = estimated_cost(product, quantity_sold)

        {
          product: product,
          quantity_sold: quantity_sold,
          revenue: revenue,
          estimated_cost: cost,
          gross_profit: revenue - cost
        }
      end
    end

    def estimated_cost(product, quantity_sold)
      return BigDecimal("0") unless product.recipe&.active?

      unit_cost = product.recipe.recipe_items.sum do |item|
        item.quantity * (item.ingredient.purchase_price || 0)
      end
      unit_cost * quantity_sold
    end

    def product_payload(data)
      {
        product_id: data.fetch(:product).id,
        code: data.fetch(:product).code,
        name: data.fetch(:product).name,
        quantity_sold: data.fetch(:quantity_sold),
        revenue: data.fetch(:revenue).to_s,
        estimated_cost: data.fetch(:estimated_cost).to_s,
        gross_profit: data.fetch(:gross_profit).to_s
      }
    end
  end
end
