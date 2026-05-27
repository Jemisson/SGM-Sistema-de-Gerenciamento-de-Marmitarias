class ProductPolicy < ApplicationPolicy
  def index?
    admin? || manager? || cashier?
  end

  def show?
    index?
  end

  def create?
    manage_products?
  end

  def update?
    manage_products?
  end

  def destroy?
    manage_products?
  end
end
