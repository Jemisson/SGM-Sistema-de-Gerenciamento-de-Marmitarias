require "rails_helper"

RSpec.describe Analytics::ProfitabilityService do
  it "returns estimated cost, gross profit and margin" do
    product = create(:product, name: "Marmita", sale_price: 30)
    ingredient = create(:ingredient, purchase_price: 5)
    create_recipe_for(product, ingredient, quantity: 2)
    create_sale_with_item(product: product, quantity: 3, total_amount: 90, sold_at: Time.zone.local(2026, 5, 10, 12))

    result = described_class.call(start_date: "2026-05-01", end_date: "2026-05-31")
    item = result.fetch(:products).first

    expect(item).to include(
      product_id: product.id,
      revenue: "90.0",
      estimated_cost: "30.0",
      gross_profit: "60.0",
      average_sale_price: "30.0",
      estimated_unit_cost: "10.0"
    )
  end
end
