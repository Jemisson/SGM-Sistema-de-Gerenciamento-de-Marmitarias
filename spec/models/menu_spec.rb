require "rails_helper"

RSpec.describe Menu, type: :model do
  it "is valid with valid attributes" do
    expect(build(:menu)).to be_valid
  end

  it "defines the expected statuses" do
    expect(described_class.statuses).to eq(
      "draft" => 0,
      "active" => 1,
      "inactive" => 2
    )
  end

  it "requires a name" do
    menu = build(:menu, name: nil)

    expect(menu).not_to be_valid
    expect(menu.errors[:name]).to include("can't be blank")
  end

  it "requires start date" do
    menu = build(:menu, start_date: nil)

    expect(menu).not_to be_valid
    expect(menu.errors[:start_date]).to include("can't be blank")
  end

  it "requires end date" do
    menu = build(:menu, end_date: nil)

    expect(menu).not_to be_valid
    expect(menu.errors[:end_date]).to include("can't be blank")
  end

  it "does not allow end date before start date" do
    menu = build(:menu, start_date: Date.current, end_date: Date.current - 1.day)

    expect(menu).not_to be_valid
    expect(menu.errors[:end_date]).to include("can't be before start date")
  end

  it "requires active to be boolean" do
    menu = build(:menu, active: nil)

    expect(menu).not_to be_valid
    expect(menu.errors[:active]).to include("is not included in the list")
  end

  it "does not allow inactive products in active menus" do
    menu = build(:menu, items_count: 0)
    menu.menu_items << build(:menu_item, menu: menu, product: create(:product, :inactive))

    expect(menu).not_to be_valid
    expect(menu.errors[:menu_items]).to include("cannot include inactive products in an active menu")
  end

  it "allows inactive products in draft menus" do
    menu = build(:menu, :draft, items_count: 0)
    menu.menu_items << build(:menu_item, menu: menu, product: create(:product, :inactive))

    expect(menu).to be_valid
  end

  it "does not allow duplicated products in nested items" do
    product = create(:product)
    menu = build(:menu, items_count: 0)
    menu.menu_items << build(:menu_item, menu: menu, product: product)
    menu.menu_items << build(:menu_item, menu: menu, product: product)

    expect(menu).not_to be_valid
    expect(menu.errors[:menu_items]).to include("cannot have duplicated products")
  end

  it "finds currently active menus for a date" do
    current_menu = create(:menu, start_date: Date.current - 1.day, end_date: Date.current + 1.day, status: :active)
    create(:menu, start_date: Date.current - 3.days, end_date: Date.current - 1.day, status: :active)
    create(:menu, start_date: Date.current - 1.day, end_date: Date.current + 1.day, status: :draft)

    expect(described_class.currently_active(Date.current)).to contain_exactly(current_menu)
  end
end
