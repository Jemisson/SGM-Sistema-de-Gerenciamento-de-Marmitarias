module Analytics
  class IngredientConsumptionService < BaseService
    def call
      {
        period: period_payload,
        ingredients: ingredient_consumption.values.sort_by { |data| -data.fetch(:quantity) }.map do |data|
          {
            ingredient_id: data.fetch(:ingredient).id,
            code: data.fetch(:ingredient).code,
            name: data.fetch(:ingredient).name,
            unit: data.fetch(:ingredient).unit,
            quantity: data.fetch(:quantity).to_s,
            estimated_cost: data.fetch(:estimated_cost).to_s
          }
        end
      }
    end

    private

    def ingredient_consumption
      sale_items.each_with_object({}) do |sale_item, result|
        recipe = sale_item.product.recipe
        next unless recipe&.active?

        recipe.recipe_items.each do |recipe_item|
          ingredient = recipe_item.ingredient
          result[ingredient.id] ||= {
            ingredient: ingredient,
            quantity: BigDecimal("0"),
            estimated_cost: BigDecimal("0")
          }
          quantity = recipe_item.quantity * sale_item.quantity
          result[ingredient.id][:quantity] += quantity
          result[ingredient.id][:estimated_cost] += quantity * (ingredient.purchase_price || 0)
        end
      end
    end
  end
end
