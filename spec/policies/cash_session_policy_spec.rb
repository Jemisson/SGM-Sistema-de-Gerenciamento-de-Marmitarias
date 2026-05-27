require "rails_helper"

RSpec.describe CashSessionPolicy do
  let(:cash_session) { build(:cash_session) }

  it "allows managers to operate cash sessions" do
    policy = described_class.new(build(:user, :manager), cash_session)

    expect(policy.index?).to be(true)
    expect(policy.current?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.open?).to be(true)
    expect(policy.close?).to be(true)
  end

  it "allows cashiers to operate cash sessions" do
    policy = described_class.new(build(:user, :cashier), cash_session)

    expect(policy.index?).to be(true)
    expect(policy.current?).to be(true)
    expect(policy.show?).to be(true)
    expect(policy.open?).to be(true)
    expect(policy.close?).to be(true)
  end

  it "forbids admins" do
    policy = described_class.new(build(:user, :admin), cash_session)

    expect(policy.index?).to be(false)
    expect(policy.current?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.open?).to be(false)
    expect(policy.close?).to be(false)
  end
end
