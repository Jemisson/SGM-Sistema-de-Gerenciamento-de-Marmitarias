require "rails_helper"

RSpec.describe Category, type: :model do
  it "is valid with valid attributes" do
    expect(build(:category)).to be_valid
  end

  it "requires a name" do
    category = build(:category, name: nil)

    expect(category).not_to be_valid
    expect(category.errors[:name]).to include("can't be blank")
  end

  it "requires a unique name" do
    create(:category, name: "Bebidas")
    category = build(:category, name: "Bebidas")

    expect(category).not_to be_valid
    expect(category.errors[:name]).to include("has already been taken")
  end

  it "requires active to be boolean" do
    category = build(:category, active: nil)

    expect(category).not_to be_valid
    expect(category.errors[:active]).to include("is not included in the list")
  end

  it "returns only active categories in the active scope" do
    active_category = create(:category)
    create(:category, :inactive)

    expect(described_class.active).to contain_exactly(active_category)
  end
end
