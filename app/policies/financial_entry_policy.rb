class FinancialEntryPolicy < ApplicationPolicy
  def index?
    manager?
  end

  def show?
    manager?
  end

  def create?
    manager?
  end

  def update?
    manager? && record.manual?
  end

  def destroy?
    manager? && record.manual?
  end
end
