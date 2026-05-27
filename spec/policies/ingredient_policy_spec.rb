require "rails_helper"

RSpec.describe IngredientPolicy do
  let(:ingredient) { build(:ingredient) }

  it "allows admin and manager to manage ingredients" do
    %i[admin manager].each do |role|
      policy = described_class.new(build(:user, role: role), ingredient)

      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end

  it "forbids cashiers" do
    policy = described_class.new(build(:user, :cashier), ingredient)

    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end
