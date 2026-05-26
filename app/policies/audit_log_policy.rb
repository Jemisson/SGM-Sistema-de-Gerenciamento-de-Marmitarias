class AuditLogPolicy < ApplicationPolicy
  def index?
    view_logs?
  end
end
