class FinancialPolicy < ApplicationPolicy
  def show?
    view_financial?
  end
end
