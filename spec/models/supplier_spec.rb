require "rails_helper"

RSpec.describe Supplier, type: :model do
  it "is valid with valid attributes" do
    expect(build(:supplier)).to be_valid
  end

  it "requires a name" do
    supplier = build(:supplier, name: nil)

    expect(supplier).not_to be_valid
    expect(supplier.errors[:name]).to include("can't be blank")
  end

  it "requires a cnpj" do
    supplier = build(:supplier, cnpj: nil)

    expect(supplier).not_to be_valid
    expect(supplier.errors[:cnpj]).to include("can't be blank")
  end

  it "requires a unique cnpj" do
    create(:supplier, cnpj: "12345678000199")
    supplier = build(:supplier, cnpj: "12345678000199")

    expect(supplier).not_to be_valid
    expect(supplier.errors[:cnpj]).to include("has already been taken")
  end

  it "allows blank email" do
    expect(build(:supplier, email: "")).to be_valid
  end

  it "requires email format when email is present" do
    supplier = build(:supplier, email: "invalid-email")

    expect(supplier).not_to be_valid
    expect(supplier.errors[:email]).to include("is invalid")
  end

  it "requires active to be boolean" do
    supplier = build(:supplier, active: nil)

    expect(supplier).not_to be_valid
    expect(supplier.errors[:active]).to include("is not included in the list")
  end

  it "limits state to two characters" do
    supplier = build(:supplier, state: "PRR")

    expect(supplier).not_to be_valid
    expect(supplier.errors[:state]).to include("is too long (maximum is 2 characters)")
  end

  it "returns only active suppliers in the active scope" do
    active_supplier = create(:supplier)
    create(:supplier, :inactive)

    expect(described_class.active).to contain_exactly(active_supplier)
  end

  it "prevents physical deletion" do
    supplier = create(:supplier)

    expect(supplier.destroy).to be(false)
    expect(described_class.exists?(supplier.id)).to be(true)
  end
end
