require "rails_helper"

RSpec.describe Reports::SalesStatisticsService do
  it "returns sales statistics grouped by payment method and product" do
    product = create(:product, name: "Marmita Fit")
    create_sale_with_item(product: product, total_amount: 80, quantity: 2, payment_method: :pix, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale_with_item(product: product, total_amount: 40, quantity: 1, payment_method: :cash, status: :canceled, sold_at: Time.zone.local(2026, 5, 10, 13))

    result = described_class.call(period: "custom", start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result).to include(
      total_sold: 1,
      total_revenue: "80.0",
      average_ticket: "80.0"
    )
    expect(result.fetch(:sales_by_payment_method)).to eq("pix" => "80.0")
    expect(result.fetch(:sales_by_product).first).to include(
      product_id: product.id,
      quantity_sold: 2,
      revenue: "80.0"
    )
  end

  def create_sale_with_item(product:, total_amount:, quantity:, payment_method: :cash, status: :confirmed, sold_at:)
    sale = build(:sale, items_count: 0, total_amount: total_amount, payment_method: payment_method, status: status, sold_at: sold_at)
    sale.sale_items << build(:sale_item, sale: sale, product: product, quantity: quantity, unit_price: total_amount / quantity, total_price: total_amount)
    sale.save!
    sale
  end
end
