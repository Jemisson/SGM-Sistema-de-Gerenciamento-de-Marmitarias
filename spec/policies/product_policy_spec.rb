require "rails_helper"

RSpec.describe ProductPolicy do
  let(:product) { build(:product) }

  it "allows admin and manager to manage products" do
    %i[admin manager].each do |role|
      policy = described_class.new(build(:user, role: role), product)

      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end

  it "allows cashiers only to list and show products" do
    policy = described_class.new(build(:user, :cashier), product)

    expect(policy.index?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end
