require "rails_helper"

RSpec.describe SaleItem, type: :model do
  it "is valid with valid attributes" do
    expect(build(:sale_item)).to be_valid
  end

  it "requires sale" do
    item = build(:sale_item, sale: nil)

    expect(item).not_to be_valid
    expect(item.errors[:sale]).to include("must exist")
  end

  it "requires product" do
    item = build(:sale_item, product: nil)

    expect(item).not_to be_valid
    expect(item.errors[:product]).to include("must exist")
  end

  it "requires quantity greater than zero" do
    item = build(:sale_item, quantity: 0)

    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to include("must be greater than 0")
  end

  it "requires integer quantity" do
    item = build(:sale_item, quantity: 1.5)

    expect(item).not_to be_valid
    expect(item.errors[:quantity]).to include("must be an integer")
  end

  it "requires unit price greater than or equal to zero" do
    item = build(:sale_item, unit_price: -1)

    expect(item).not_to be_valid
    expect(item.errors[:unit_price]).to include("must be greater than or equal to 0")
  end

  it "requires total price greater than or equal to zero" do
    item = build(:sale_item, total_price: -1)

    expect(item).not_to be_valid
    expect(item.errors[:total_price]).to include("must be greater than or equal to 0")
  end
end
