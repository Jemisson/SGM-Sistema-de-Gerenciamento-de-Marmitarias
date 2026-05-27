require "rails_helper"

RSpec.describe Analytics::TrendService do
  it "returns daily trends by default" do
    product = create(:product)
    create_sale_with_item(product: product, quantity: 2, total_amount: 40, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale_with_item(product: product, quantity: 1, total_amount: 20, sold_at: Time.zone.local(2026, 5, 11, 12))

    result = described_class.call(start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result.fetch(:granularity)).to eq("day")
    expect(result.fetch(:points)).to include(
      {
        period: "2026-05-10",
        total_revenue: "40.0",
        quantity_sold: 2
      },
      {
        period: "2026-05-11",
        total_revenue: "20.0",
        quantity_sold: 1
      }
    )
  end

  it "validates granularity" do
    expect do
      described_class.call(start_date: "2026-05-01", end_date: "2026-05-31", granularity: "hour")
    end.to raise_error(ArgumentError, /granularity is invalid/)
  end
end
