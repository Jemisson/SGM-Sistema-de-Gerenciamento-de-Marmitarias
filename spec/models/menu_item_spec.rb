require "rails_helper"

RSpec.describe MenuItem, type: :model do
  it "is valid with valid attributes" do
    expect(build(:menu_item)).to be_valid
  end

  it "requires a menu" do
    item = build(:menu_item, menu: nil)

    expect(item).not_to be_valid
    expect(item.errors[:menu]).to include("must exist")
  end

  it "requires a product" do
    item = build(:menu_item, product: nil)

    expect(item).not_to be_valid
    expect(item.errors[:product]).to include("must exist")
  end

  it "requires available to be boolean" do
    item = build(:menu_item, available: nil)

    expect(item).not_to be_valid
    expect(item.errors[:available]).to include("is not included in the list")
  end

  it "does not allow duplicated product in the same menu" do
    menu = create(:menu)
    product = create(:product)
    create(:menu_item, menu: menu, product: product)

    item = build(:menu_item, menu: menu, product: product)

    expect(item).not_to be_valid
    expect(item.errors[:product_id]).to include("has already been taken")
  end

  it "requires price override greater than zero when informed" do
    item = build(:menu_item, price_override: 0)

    expect(item).not_to be_valid
    expect(item.errors[:price_override]).to include("must be greater than 0")
  end

  it "allows blank price override" do
    expect(build(:menu_item, price_override: nil)).to be_valid
  end
end
