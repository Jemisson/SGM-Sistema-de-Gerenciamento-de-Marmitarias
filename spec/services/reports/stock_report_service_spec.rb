require "rails_helper"

RSpec.describe Reports::StockReportService do
  it "returns stock alerts and consumption summary" do
    below = create(:ingredient, name: "Arroz", current_stock: 1, minimum_stock: 2)
    expiring = create(:ingredient, name: "Feijao", expiration_date: 10.days.from_now.to_date)
    create(:stock_movement, ingredient: below, movement_type: :sale_consumption, quantity: 3, occurred_at: Time.zone.local(2026, 5, 10, 12))

    result = described_class.call(period: "custom", start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result.fetch(:ingredients_below_minimum_stock).pluck(:id)).to include(below.id)
    expect(result.fetch(:ingredients_near_expiration).pluck(:id)).to include(expiring.id)
    expect(result.fetch(:total_ingredients)).to eq(Ingredient.active.count)
    expect(result.fetch(:stock_consumption_summary).first).to include(
      ingredient_id: below.id,
      quantity: "3.0"
    )
  end
end
