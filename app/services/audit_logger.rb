class AuditLogger
  def self.call(...)
    new(...).call
  end

  def initialize(user:, action:, auditable: nil, request: nil, metadata: {})
    @user = user
    @action = action
    @auditable = auditable
    @request = request
    @metadata = metadata || {}
  end

  def call
    AuditLog.create!(
      user: user,
      action: action,
      auditable: auditable,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent,
      metadata: metadata,
      occurred_at: Time.current
    )
  end

  private

  attr_reader :user, :action, :auditable, :request, :metadata
end
