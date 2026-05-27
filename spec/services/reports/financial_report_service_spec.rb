require "rails_helper"

RSpec.describe Reports::FinancialReportService do
  it "returns income, expense, balance and totals by payment method" do
    create_sale(total_amount: 100, payment_method: :pix, sold_at: Time.zone.local(2026, 5, 10, 12))
    create_sale(total_amount: 50, payment_method: :cash, status: :canceled, sold_at: Time.zone.local(2026, 5, 10, 13))
    create(:financial_entry, entry_type: :income, amount: 30, payment_method: :cash, occurred_at: Time.zone.local(2026, 5, 10, 14))
    create(:financial_entry, :expense, amount: 20, payment_method: :bank_transfer, occurred_at: Time.zone.local(2026, 5, 10, 15))
    create(:financial_entry, amount: 999, payment_method: :pix, source_type: "Sale", source_id: 999, occurred_at: Time.zone.local(2026, 5, 10, 16))

    result = described_class.call(period: "custom", start_date: "2026-05-01", end_date: "2026-05-31")

    expect(result).to include(
      incomes: "130.0",
      expenses: "20.0",
      balance: "110.0"
    )
    expect(result.fetch(:totals_by_payment_method)).to include(
      "pix" => "100.0",
      "cash" => "30.0",
      "bank_transfer" => "20.0"
    )
  end

  def create_sale(total_amount:, payment_method:, status: :confirmed, sold_at:)
    sale = build(:sale, items_count: 0, total_amount: total_amount, payment_method: payment_method, status: status, sold_at: sold_at)
    sale.sale_items << build(:sale_item, sale: sale, unit_price: total_amount, total_price: total_amount)
    sale.save!
    sale
  end
end
