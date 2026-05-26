require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(user, nil) }

  context "when user is admin" do
    let(:user) { build(:user, :admin) }

    it "allows administrative and management access" do
      expect(policy.manage_users?).to be(true)
      expect(policy.manage_catalog?).to be(true)
      expect(policy.manage_suppliers?).to be(true)
      expect(policy.manage_inputs?).to be(true)
      expect(policy.manage_products?).to be(true)
      expect(policy.manage_recipes?).to be(true)
      expect(policy.manage_menus?).to be(true)
      expect(policy.view_reports?).to be(true)
      expect(policy.view_analytics?).to be(true)
      expect(policy.view_logs?).to be(true)
    end

    it "does not allow direct sales or cash register operations" do
      expect(policy.register_sales?).to be(false)
      expect(policy.manage_cash_register?).to be(false)
    end
  end

  context "when user is manager" do
    let(:user) { build(:user, :manager) }

    it "allows management, cash register, reports, analytics and financial access" do
      expect(policy.manage_catalog?).to be(true)
      expect(policy.manage_suppliers?).to be(true)
      expect(policy.manage_inputs?).to be(true)
      expect(policy.manage_products?).to be(true)
      expect(policy.manage_recipes?).to be(true)
      expect(policy.manage_menus?).to be(true)
      expect(policy.manage_cash_register?).to be(true)
      expect(policy.view_reports?).to be(true)
      expect(policy.view_analytics?).to be(true)
      expect(policy.view_financial?).to be(true)
    end

    it "does not allow user management or direct sales" do
      expect(policy.manage_users?).to be(false)
      expect(policy.register_sales?).to be(false)
    end

    it "allows log visualization" do
      expect(policy.view_logs?).to be(true)
    end
  end

  context "when user is cashier" do
    let(:user) { build(:user, :cashier) }

    it "allows direct sales and cash register operations" do
      expect(policy.register_sales?).to be(true)
      expect(policy.manage_cash_register?).to be(true)
    end

    it "does not allow administrative or management access" do
      expect(policy.manage_users?).to be(false)
      expect(policy.manage_catalog?).to be(false)
      expect(policy.manage_suppliers?).to be(false)
      expect(policy.manage_inputs?).to be(false)
      expect(policy.manage_products?).to be(false)
      expect(policy.manage_recipes?).to be(false)
      expect(policy.manage_menus?).to be(false)
      expect(policy.view_reports?).to be(false)
      expect(policy.view_analytics?).to be(false)
      expect(policy.view_logs?).to be(false)
      expect(policy.view_financial?).to be(false)
    end
  end

  context "when there is no authenticated user" do
    let(:user) { nil }

    it "denies all base permissions" do
      expect(policy.manage_users?).to be(false)
      expect(policy.manage_catalog?).to be(false)
      expect(policy.manage_cash_register?).to be(false)
      expect(policy.register_sales?).to be(false)
      expect(policy.view_reports?).to be(false)
      expect(policy.view_analytics?).to be(false)
      expect(policy.view_logs?).to be(false)
      expect(policy.view_financial?).to be(false)
    end
  end
end
