class MenuPolicy < ApplicationPolicy
  def index?
    admin? || manager? || cashier?
  end

  def current?
    index?
  end

  def show?
    index?
  end

  def create?
    manage_menus?
  end

  def update?
    manage_menus?
  end

  def destroy?
    manage_menus?
  end
end
