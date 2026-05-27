require "rails_helper"

RSpec.describe FinancialEntry, type: :model do
  it "is valid with valid attributes" do
    expect(build(:financial_entry)).to be_valid
  end

  it "defines entry types" do
    expect(described_class.entry_types).to eq(
      "income" => 0,
      "expense" => 1
    )
  end

  it "defines payment methods" do
    expect(described_class.payment_methods).to eq(
      "cash" => 0,
      "credit_card" => 1,
      "debit_card" => 2,
      "pix" => 3,
      "bank_transfer" => 4,
      "other" => 5
    )
  end

  it "requires user" do
    entry = build(:financial_entry, user: nil)

    expect(entry).not_to be_valid
    expect(entry.errors[:user]).to include("must exist")
  end

  it "requires amount greater than zero" do
    entry = build(:financial_entry, amount: 0)

    expect(entry).not_to be_valid
    expect(entry.errors[:amount]).to include("must be greater than 0")
  end

  it "requires occurred at" do
    entry = build(:financial_entry, occurred_at: nil)

    expect(entry).not_to be_valid
    expect(entry.errors[:occurred_at]).to include("can't be blank")
  end

  it "requires description for expenses" do
    entry = build(:financial_entry, :expense, description: nil)

    expect(entry).not_to be_valid
    expect(entry.errors[:description]).to include("can't be blank")
  end

  it "requires active to be boolean" do
    entry = build(:financial_entry, active: nil)

    expect(entry).not_to be_valid
    expect(entry.errors[:active]).to include("is not included in the list")
  end

  it "identifies manual entries" do
    expect(build(:financial_entry)).to be_manual
    expect(build(:financial_entry, :from_sale)).not_to be_manual
  end
end
