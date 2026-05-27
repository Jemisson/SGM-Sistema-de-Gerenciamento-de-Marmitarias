class CategoryPolicy < ApplicationPolicy
  def index?
    admin? || manager? || cashier?
  end

  def show?
    index?
  end

  def create?
    manage_catalog?
  end

  def update?
    manage_catalog?
  end

  def destroy?
    manage_catalog?
  end
end
