require "rails_helper"

RSpec.describe Reports::OverviewService do
  it "returns overview indicators ignoring canceled sales" do
    product = create(:product, name: "Marmita Top")
    ingredient = create(:ingredient, current_stock: 10, purchase_price: 5)
    create_sale_with_item(product: product, total_amount: 100, quantity: 2, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale_with_item(product: product, total_amount: 50, quantity: 1, status: :canceled, sold_at: Time.zone.local(2026, 5, 10, 13))
    create(:stock_movement, ingredient: ingredient, movement_type: :sale_consumption, quantity: 4, occurred_at: Time.zone.local(2026, 5, 10, 12))

    result = described_class.call(period: "custom", start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result).to include(
      total_revenue: "100.0",
      average_ticket: "100.0",
      gross_profit: "80.0",
      stock_items_count: Ingredient.active.count
    )
    expect(result.fetch(:top_products).first).to include(
      product_id: product.id,
      quantity_sold: 2,
      revenue: "100.0"
    )
  end

  it "validates period range" do
    expect do
      described_class.call(period: "custom", start_date: "2026-05-31", end_date: "2026-05-01")
    end.to raise_error(ArgumentError, /end_date can't be before start_date/)
  end

  def create_sale_with_item(product:, total_amount:, quantity:, status: :confirmed, sold_at:)
    sale = build(:sale, items_count: 0, total_amount: total_amount, status: status, sold_at: sold_at)
    sale.sale_items << build(:sale_item, sale: sale, product: product, quantity: quantity, unit_price: total_amount / quantity, total_price: total_amount)
    sale.save!
    sale
  end
end
