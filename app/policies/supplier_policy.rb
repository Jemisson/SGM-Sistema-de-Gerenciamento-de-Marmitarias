class SupplierPolicy < ApplicationPolicy
  def index?
    manage_suppliers?
  end

  def show?
    manage_suppliers?
  end

  def create?
    manage_suppliers?
  end

  def update?
    manage_suppliers?
  end

  def destroy?
    manage_suppliers?
  end
end
