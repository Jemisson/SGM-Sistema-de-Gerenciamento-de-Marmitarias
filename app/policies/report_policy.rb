class ReportPolicy < ApplicationPolicy
  def show?
    view_reports?
  end
end
