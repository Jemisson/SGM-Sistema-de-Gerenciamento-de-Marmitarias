require "rails_helper"

RSpec.describe Sale, type: :model do
  it "is valid with valid attributes" do
    expect(build(:sale)).to be_valid
  end

  it "defines payment methods" do
    expect(described_class.payment_methods).to eq(
      "cash" => 0,
      "credit_card" => 1,
      "debit_card" => 2,
      "pix" => 3
    )
  end

  it "defines statuses" do
    expect(described_class.statuses).to eq(
      "confirmed" => 0,
      "canceled" => 1
    )
  end

  it "requires cash session" do
    sale = build(:sale, cash_session: nil)

    expect(sale).not_to be_valid
    expect(sale.errors[:cash_session]).to include("must exist")
  end

  it "requires user" do
    sale = build(:sale, user: nil)

    expect(sale).not_to be_valid
    expect(sale.errors[:user]).to include("must exist")
  end

  it "requires total amount greater than or equal to zero" do
    sale = build(:sale, total_amount: -1)

    expect(sale).not_to be_valid
    expect(sale.errors[:total_amount]).to include("must be greater than or equal to 0")
  end

  it "requires sold at" do
    sale = build(:sale, sold_at: nil)

    expect(sale).not_to be_valid
    expect(sale.errors[:sold_at]).to include("can't be blank")
  end

  it "requires at least one item" do
    sale = build(:sale, items_count: 0)

    expect(sale).not_to be_valid
    expect(sale.errors[:sale_items]).to include("must have at least one item")
  end
end
