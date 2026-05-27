class SalePolicy < ApplicationPolicy
  def index?
    manage_cash_register?
  end

  def show?
    manage_cash_register?
  end

  def create?
    manage_cash_register?
  end

  def cancel?
    manage_cash_register?
  end
end
