class SalePolicy < ApplicationPolicy
  def create?
    register_sales?
  end
end
