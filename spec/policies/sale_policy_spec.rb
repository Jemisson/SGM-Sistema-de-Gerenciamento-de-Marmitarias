require "rails_helper"

RSpec.describe SalePolicy do
  let(:sale) { build(:sale) }

  it "allows managers and cashiers to manage sales" do
    %i[manager cashier].each do |role|
      policy = described_class.new(build(:user, role: role), sale)

      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.cancel?).to be(true)
    end
  end

  it "forbids admins" do
    policy = described_class.new(build(:user, :admin), sale)

    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.cancel?).to be(false)
  end
end
