require "rails_helper"

RSpec.describe FinancialEntryPolicy do
  it "allows managers to manage manual entries" do
    entry = build(:financial_entry)
    policy = described_class.new(build(:user, :manager), entry)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.create?).to be(true)
    expect(policy.update?).to be(true)
    expect(policy.destroy?).to be(true)
  end

  it "does not allow managers to change source entries" do
    entry = build(:financial_entry, :from_sale)
    policy = described_class.new(build(:user, :manager), entry)

    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  it "forbids admins and cashiers" do
    entry = build(:financial_entry)

    [build(:user, :admin), build(:user, :cashier)].each do |user|
      policy = described_class.new(user, entry)

      expect(policy.index?).to be(false)
      expect(policy.show?).to be(false)
      expect(policy.create?).to be(false)
      expect(policy.update?).to be(false)
      expect(policy.destroy?).to be(false)
    end
  end
end
