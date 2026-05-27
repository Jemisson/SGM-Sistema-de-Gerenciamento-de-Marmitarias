class RecipePolicy < ApplicationPolicy
  def index?
    manage_recipes?
  end

  def show?
    manage_recipes?
  end

  def create?
    manage_recipes?
  end

  def update?
    manage_recipes?
  end

  def destroy?
    manage_recipes?
  end
end
