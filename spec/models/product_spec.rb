require "rails_helper"

RSpec.describe Product, type: :model do
  it "is valid with valid attributes" do
    expect(build(:product)).to be_valid
  end

  it "requires a code" do
    product = build(:product, code: nil)

    expect(product).not_to be_valid
    expect(product.errors[:code]).to include("can't be blank")
  end

  it "requires a unique code" do
    create(:product, code: "M001")
    product = build(:product, code: "M001")

    expect(product).not_to be_valid
    expect(product.errors[:code]).to include("has already been taken")
  end

  it "requires a name" do
    product = build(:product, name: nil)

    expect(product).not_to be_valid
    expect(product.errors[:name]).to include("can't be blank")
  end

  it "requires a category" do
    product = build(:product, category: nil)

    expect(product).not_to be_valid
    expect(product.errors[:category]).to include("must exist")
  end

  it "requires sale price greater than zero" do
    product = build(:product, sale_price: 0)

    expect(product).not_to be_valid
    expect(product.errors[:sale_price]).to include("must be greater than 0")
  end

  it "requires active to be boolean" do
    product = build(:product, active: nil)

    expect(product).not_to be_valid
    expect(product.errors[:active]).to include("is not included in the list")
  end

  it "can have an attached image" do
    product = build(:product)

    product.image.attach(
      io: StringIO.new("fake image"),
      filename: "marmita.jpg",
      content_type: "image/jpeg"
    )

    expect(product.image).to be_attached
  end
end
