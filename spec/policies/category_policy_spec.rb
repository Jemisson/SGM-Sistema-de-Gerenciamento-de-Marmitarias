require "rails_helper"

RSpec.describe CategoryPolicy do
  let(:category) { build(:category) }

  it "allows admin, manager and cashier to list and show" do
    %i[admin manager cashier].each do |role|
      user = build(:user, role: role)
      policy = described_class.new(user, category)

      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
    end
  end

  it "allows only admin and manager to create, update and destroy" do
    admin_policy = described_class.new(build(:user, :admin), category)
    manager_policy = described_class.new(build(:user, :manager), category)
    cashier_policy = described_class.new(build(:user, :cashier), category)

    expect(admin_policy.create?).to be(true)
    expect(admin_policy.update?).to be(true)
    expect(admin_policy.destroy?).to be(true)

    expect(manager_policy.create?).to be(true)
    expect(manager_policy.update?).to be(true)
    expect(manager_policy.destroy?).to be(true)

    expect(cashier_policy.create?).to be(false)
    expect(cashier_policy.update?).to be(false)
    expect(cashier_policy.destroy?).to be(false)
  end
end
