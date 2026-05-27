class StockMovementPolicy < ApplicationPolicy
  def index?
    manage_inputs?
  end

  def show?
    manage_inputs?
  end

  def create?
    manage_inputs?
  end
end
