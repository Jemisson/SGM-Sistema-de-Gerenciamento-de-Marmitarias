require "rails_helper"

RSpec.describe Analytics::AbcCurveService do
  it "classifies products by revenue participation ignoring canceled sales" do
    product_a = create(:product, name: "Produto A")
    product_b = create(:product, name: "Produto B")
    create_sale_with_item(product: product_a, quantity: 4, total_amount: 80, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale_with_item(product: product_b, quantity: 1, total_amount: 20, sold_at: Time.zone.local(2026, 5, 10, 13))
    create_sale_with_item(product: product_b, quantity: 1, total_amount: 999, sold_at: Time.zone.local(2026, 5, 10, 14), status: :canceled)

    result = described_class.call(start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result.fetch(:total_revenue)).to eq("100.0")
    expect(result.fetch(:products).first).to include(
      product_id: product_a.id,
      revenue: "80.0",
      abc_class: "A"
    )
    expect(result.fetch(:products).last).to include(
      product_id: product_b.id,
      revenue: "20.0",
      abc_class: "C"
    )
  end
end
