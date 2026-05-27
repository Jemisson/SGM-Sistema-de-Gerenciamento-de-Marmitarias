require "rails_helper"

RSpec.describe Analytics::IngredientConsumptionService do
  it "calculates ingredient consumption from recipes and sales" do
    product = create(:product)
    ingredient = create(:ingredient, purchase_price: 4)
    create_recipe_for(product, ingredient, quantity: 0.500)
    create_sale_with_item(product: product, quantity: 3, total_amount: 90, sold_at: Time.zone.local(2026, 5, 10, 12))

    result = described_class.call(start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result.fetch(:ingredients).first).to include(
      ingredient_id: ingredient.id,
      quantity: "1.5",
      estimated_cost: "6.0"
    )
  end
end
