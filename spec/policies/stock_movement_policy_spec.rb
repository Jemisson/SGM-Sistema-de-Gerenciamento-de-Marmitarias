require "rails_helper"

RSpec.describe StockMovementPolicy do
  let(:stock_movement) { build(:stock_movement) }

  it "allows admin and manager to list, show and create stock movements" do
    %i[admin manager].each do |role|
      policy = described_class.new(build(:user, role: role), stock_movement)

      expect(policy.index?).to be(true)
      expect(policy.show?).to be(true)
      expect(policy.create?).to be(true)
    end
  end

  it "forbids cashiers" do
    policy = described_class.new(build(:user, :cashier), stock_movement)

    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
  end
end
