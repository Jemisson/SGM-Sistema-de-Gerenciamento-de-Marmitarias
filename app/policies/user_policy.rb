class UserPolicy < ApplicationPolicy
  def index?
    manage_users?
  end

  def show?
    manage_users?
  end

  def create?
    manage_users?
  end

  def update?
    manage_users?
  end

  def destroy?
    manage_users?
  end
end
