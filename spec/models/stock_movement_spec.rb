require "rails_helper"

RSpec.describe StockMovement, type: :model do
  it "is valid with valid attributes" do
    expect(build(:stock_movement)).to be_valid
  end

  it "defines the expected movement types" do
    expect(described_class.movement_types).to eq(
      "entry" => 0,
      "exit" => 1,
      "adjustment" => 2,
      "production_consumption" => 3,
      "sale_consumption" => 4
    )
  end

  it "requires an ingredient" do
    movement = build(:stock_movement, ingredient: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:ingredient]).to include("must exist")
  end

  it "requires a user" do
    movement = build(:stock_movement, user: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:user]).to include("must exist")
  end

  it "requires a movement type" do
    movement = build(:stock_movement, movement_type: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:movement_type]).to include("can't be blank")
  end

  it "does not allow unknown movement types" do
    movement = build(:stock_movement, movement_type: "unknown")

    expect(movement).not_to be_valid
    expect(movement.errors[:movement_type]).to include("is not included in the list")
  end

  it "requires quantity greater than zero" do
    movement = build(:stock_movement, quantity: 0)

    expect(movement).not_to be_valid
    expect(movement.errors[:quantity]).to include("must be greater than 0")
  end

  it "requires occurred_at" do
    movement = build(:stock_movement, occurred_at: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:occurred_at]).to include("can't be blank")
  end

  it "requires reason for adjustment" do
    movement = build(:stock_movement, :adjustment, reason: nil)

    expect(movement).not_to be_valid
    expect(movement.errors[:reason]).to include("can't be blank")
  end

  it "does not allow negative unit cost" do
    movement = build(:stock_movement, unit_cost: -1)

    expect(movement).not_to be_valid
    expect(movement.errors[:unit_cost]).to include("must be greater than or equal to 0")
  end
end
