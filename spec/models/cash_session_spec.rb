require "rails_helper"

RSpec.describe CashSession, type: :model do
  it "is valid with valid attributes" do
    expect(build(:cash_session)).to be_valid
  end

  it "defines the expected statuses" do
    expect(described_class.statuses).to eq(
      "opened" => 0,
      "closed" => 1
    )
  end

  it "requires opened by" do
    session = build(:cash_session, opened_by: nil)

    expect(session).not_to be_valid
    expect(session.errors[:opened_by]).to include("must exist")
  end

  it "requires opening amount greater than or equal to zero" do
    session = build(:cash_session, opening_amount: -1)

    expect(session).not_to be_valid
    expect(session.errors[:opening_amount]).to include("must be greater than or equal to 0")
  end

  it "requires opened at" do
    session = build(:cash_session, opened_at: nil)

    expect(session).not_to be_valid
    expect(session.errors[:opened_at]).to include("can't be blank")
  end

  it "requires close fields when closed" do
    session = build(:cash_session, status: :closed, closing_amount: nil, closed_at: nil, closed_by: nil)

    expect(session).not_to be_valid
    expect(session.errors[:closing_amount]).to include("can't be blank")
    expect(session.errors[:closed_at]).to include("can't be blank")
    expect(session.errors[:closed_by]).to include("can't be blank")
  end

  it "does not allow closed at before opened at" do
    session = build(:cash_session, :closed, opened_at: Time.zone.local(2026, 5, 27, 10), closed_at: Time.zone.local(2026, 5, 27, 9))

    expect(session).not_to be_valid
    expect(session.errors[:closed_at]).to include("can't be before opened at")
  end
end
