require "rails_helper"

RSpec.describe Ingredient, type: :model do
  it "is valid with valid attributes" do
    expect(build(:ingredient)).to be_valid
  end

  it "requires a code" do
    ingredient = build(:ingredient, code: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:code]).to include("can't be blank")
  end

  it "requires a unique code" do
    create(:ingredient, code: "INS001")
    ingredient = build(:ingredient, code: "INS001")

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:code]).to include("has already been taken")
  end

  it "requires a name" do
    ingredient = build(:ingredient, name: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:name]).to include("can't be blank")
  end

  it "requires a category" do
    ingredient = build(:ingredient, category: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:category]).to include("must exist")
  end

  it "requires a unit" do
    ingredient = build(:ingredient, unit: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:unit]).to include("can't be blank")
  end

  it "does not allow negative current stock" do
    ingredient = build(:ingredient, current_stock: -1)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:current_stock]).to include("must be greater than or equal to 0")
  end

  it "does not allow negative minimum stock" do
    ingredient = build(:ingredient, minimum_stock: -1)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:minimum_stock]).to include("must be greater than or equal to 0")
  end

  it "does not allow negative purchase price" do
    ingredient = build(:ingredient, purchase_price: -1)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:purchase_price]).to include("must be greater than or equal to 0")
  end

  it "allows blank purchase price" do
    expect(build(:ingredient, purchase_price: nil)).to be_valid
  end

  it "does not allow manufacturing date after expiration date" do
    ingredient = build(
      :ingredient,
      manufacturing_date: Date.current,
      expiration_date: 1.day.ago.to_date
    )

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:manufacturing_date]).to include("can't be after expiration date")
  end

  it "does not allow received_at before manufacturing date" do
    ingredient = build(
      :ingredient,
      manufacturing_date: Date.current,
      received_at: 1.day.ago.to_date
    )

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:received_at]).to include("can't be before manufacturing date")
  end

  it "requires active to be boolean" do
    ingredient = build(:ingredient, active: nil)

    expect(ingredient).not_to be_valid
    expect(ingredient.errors[:active]).to include("is not included in the list")
  end

  it "returns only active ingredients in the active scope" do
    active_ingredient = create(:ingredient)
    create(:ingredient, :inactive)

    expect(described_class.active).to contain_exactly(active_ingredient)
  end

  it "returns ingredients below minimum stock" do
    ingredient = create(:ingredient, :below_minimum_stock)
    create(:ingredient, current_stock: 10, minimum_stock: 2)

    expect(described_class.below_minimum_stock).to contain_exactly(ingredient)
  end
end
