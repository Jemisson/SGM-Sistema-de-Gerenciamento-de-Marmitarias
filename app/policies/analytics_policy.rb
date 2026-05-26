class AnalyticsPolicy < ApplicationPolicy
  def show?
    view_analytics?
  end
end
