require "rails_helper"

RSpec.describe CashMovement, type: :model do
  it "is valid with valid attributes" do
    expect(build(:cash_movement)).to be_valid
  end

  it "defines the expected movement types" do
    expect(described_class.movement_types).to eq(
      "opening" => 0,
      "sale" => 1,
      "income" => 2,
      "expense" => 3,
      "adjustment" => 4,
      "closing" => 5
    )
  end

  it "requires a cash session" do
    movement = build(:cash_movement, cash_session: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:cash_session]).to include("must exist")
  end

  it "requires a user" do
    movement = build(:cash_movement, user: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:user]).to include("must exist")
  end

  it "requires an amount" do
    movement = build(:cash_movement, amount: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:amount]).to include("is not a number")
  end

  it "requires occurred at" do
    movement = build(:cash_movement, occurred_at: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:occurred_at]).to include("can't be blank")
  end

  it "does not allow movements in closed cash sessions" do
    movement = build(:cash_movement, cash_session: create(:cash_session, :closed))

    expect(movement).not_to be_valid
    expect(movement.errors[:cash_session]).to include("must be opened")
  end
end
