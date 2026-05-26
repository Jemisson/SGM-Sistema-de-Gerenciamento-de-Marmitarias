class ManagementPolicy < ApplicationPolicy
  def access?
    manage_catalog?
  end

  def manage?
    access?
  end
end
