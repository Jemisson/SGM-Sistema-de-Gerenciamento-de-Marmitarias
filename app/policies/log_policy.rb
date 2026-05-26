class LogPolicy < ApplicationPolicy
  def index?
    view_logs?
  end

  def show?
    view_logs?
  end
end
