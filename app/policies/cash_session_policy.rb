class CashSessionPolicy < ApplicationPolicy
  def index?
    manage_cash_register?
  end

  def current?
    manage_cash_register?
  end

  def show?
    manage_cash_register?
  end

  def open?
    manage_cash_register?
  end

  def close?
    manage_cash_register?
  end
end
