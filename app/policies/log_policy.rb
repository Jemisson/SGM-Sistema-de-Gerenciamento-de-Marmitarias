class LogPolicy < ApplicationPolicy
  def show?
    view_logs?
  end
end
