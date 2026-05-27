require "rails_helper"

RSpec.describe "Module policies" do
  let(:admin) { build(:user, :admin) }
  let(:manager) { build(:user, :manager) }
  let(:cashier) { build(:user, :cashier) }

  it "allows only admins to manage users" do
    expect(UserPolicy.new(admin, User).create?).to be(true)
    expect(UserPolicy.new(manager, User).create?).to be(false)
    expect(UserPolicy.new(cashier, User).create?).to be(false)
  end

  it "allows admins and managers to access management modules" do
    expect(ManagementPolicy.new(admin, :management).manage?).to be(true)
    expect(ManagementPolicy.new(manager, :management).manage?).to be(true)
    expect(ManagementPolicy.new(cashier, :management).manage?).to be(false)
  end

  it "allows managers and cashiers to register sales" do
    expect(SalePolicy.new(admin, :sale).create?).to be(false)
    expect(SalePolicy.new(manager, :sale).create?).to be(true)
    expect(SalePolicy.new(cashier, :sale).create?).to be(true)
  end

  it "allows managers and cashiers to control cash register" do
    expect(CashRegisterPolicy.new(admin, :cash_register).open?).to be(false)
    expect(CashRegisterPolicy.new(manager, :cash_register).open?).to be(true)
    expect(CashRegisterPolicy.new(cashier, :cash_register).open?).to be(true)
  end

  it "allows admins and managers to view reports and analytics" do
    expect(ReportPolicy.new(admin, :report).show?).to be(true)
    expect(ReportPolicy.new(manager, :report).show?).to be(true)
    expect(ReportPolicy.new(cashier, :report).show?).to be(false)

    expect(AnalyticsPolicy.new(admin, :analytics).show?).to be(true)
    expect(AnalyticsPolicy.new(manager, :analytics).show?).to be(true)
    expect(AnalyticsPolicy.new(cashier, :analytics).show?).to be(false)
  end

  it "limits logs to admins and managers, and financial views to managers" do
    expect(LogPolicy.new(admin, :log).show?).to be(true)
    expect(LogPolicy.new(manager, :log).show?).to be(true)
    expect(LogPolicy.new(cashier, :log).show?).to be(false)

    expect(FinancialPolicy.new(admin, :financial).show?).to be(false)
    expect(FinancialPolicy.new(manager, :financial).show?).to be(true)
    expect(FinancialPolicy.new(cashier, :financial).show?).to be(false)
  end
end
