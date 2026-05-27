require "rails_helper"

RSpec.describe Analytics::ProductPerformanceService do
  it "returns most and least sold products" do
    product_a = create(:product, name: "Mais vendido")
    product_b = create(:product, name: "Menos vendido")
    create_sale_with_item(product: product_a, quantity: 5, total_amount: 100, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale_with_item(product: product_b, quantity: 1, total_amount: 20, sold_at: Time.zone.local(2026, 5, 10, 13))

    result = described_class.call(start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result.fetch(:most_sold_products).first).to include(product_id: product_a.id, quantity_sold: 5)
    expect(result.fetch(:least_sold_products).first).to include(product_id: product_b.id, quantity_sold: 1)
  end
end
