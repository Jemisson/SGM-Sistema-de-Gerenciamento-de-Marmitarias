require "rails_helper"

RSpec.describe MenuPolicy do
  let(:menu) { build(:menu) }

  it "allows admin and manager to manage menus" do
    %i[admin manager].each do |role|
      policy = described_class.new(build(:user, role: role), menu)

      expect(policy.index?).to be(true)
      expect(policy.current?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
      expect(policy.update?).to be(true)
      expect(policy.destroy?).to be(true)
    end
  end

  it "allows cashiers only to list current and show menus" do
    policy = described_class.new(build(:user, :cashier), menu)

    expect(policy.index?).to be(true)
    expect(policy.current?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.create?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.destroy?).to be(false)
  end
end
