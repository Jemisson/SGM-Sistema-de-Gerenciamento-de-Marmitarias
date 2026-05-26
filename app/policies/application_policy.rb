# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def manage_users?
    admin?
  end

  def manage_catalog?
    admin? || manager?
  end

  def manage_suppliers?
    admin? || manager?
  end

  def manage_inputs?
    admin? || manager?
  end

  def manage_products?
    admin? || manager?
  end

  def manage_recipes?
    admin? || manager?
  end

  def manage_menus?
    admin? || manager?
  end

  def view_reports?
    admin? || manager?
  end

  def view_analytics?
    admin? || manager?
  end

  def view_logs?
    admin?
  end

  def view_financial?
    manager?
  end

  def manage_cash_register?
    manager? || cashier?
  end

  def register_sales?
    cashier?
  end

  private

  def admin?
    user&.admin? || false
  end

  def manager?
    user&.manager? || false
  end

  def cashier?
    user&.cashier? || false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
