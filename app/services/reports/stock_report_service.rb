module Reports
  class StockReportService
    def self.call(...)
      new(...).call
    end

    def initialize(params = {})
      @period = PeriodRange.call(params)
    end

    def call
      {
        period: period_payload,
        ingredients_below_minimum_stock: ingredients_below_minimum_stock,
        ingredients_near_expiration: ingredients_near_expiration,
        total_ingredients: Ingredient.active.count,
        stock_consumption_summary: stock_consumption_summary
      }
    end

    private

    attr_reader :period

    def ingredients_below_minimum_stock
      Ingredient.active.below_minimum_stock.order(:name).map { |ingredient| ingredient_payload(ingredient) }
    end

    def ingredients_near_expiration
      Ingredient.active
                .where(expiration_date: Time.zone.today..30.days.from_now.to_date)
                .order(:expiration_date, :name)
                .map { |ingredient| ingredient_payload(ingredient) }
    end

    def stock_consumption_summary
      StockMovement.where(movement_type: %i[exit production_consumption sale_consumption])
                   .where(occurred_at: period.start_date..period.end_date)
                   .joins(:ingredient)
                   .group("ingredients.id", "ingredients.code", "ingredients.name", "ingredients.unit")
                   .select(
                     "ingredients.id AS ingredient_id",
                     "ingredients.code AS ingredient_code",
                     "ingredients.name AS ingredient_name",
                     "ingredients.unit AS ingredient_unit",
                     "SUM(stock_movements.quantity) AS quantity"
                   )
                   .order(Arel.sql("SUM(stock_movements.quantity) DESC"))
                   .map do |row|
        {
          ingredient_id: row.ingredient_id,
          code: row.ingredient_code,
          name: row.ingredient_name,
          unit: row.ingredient_unit,
          quantity: row.quantity.to_s
        }
      end
    end

    def ingredient_payload(ingredient)
      {
        id: ingredient.id,
        code: ingredient.code,
        name: ingredient.name,
        current_stock: ingredient.current_stock.to_s,
        minimum_stock: ingredient.minimum_stock.to_s,
        unit: ingredient.unit,
        expiration_date: ingredient.expiration_date&.iso8601
      }
    end

    def period_payload
      {
        start_date: period.start_date.iso8601,
        end_date: period.end_date.iso8601
      }
    end
  end
end
