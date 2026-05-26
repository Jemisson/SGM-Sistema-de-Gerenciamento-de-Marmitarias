require "rails_helper"

RSpec.describe AuditLogger do
  describe ".call" do
    it "creates an audit log with request data and metadata" do
      user = create(:user)
      request = instance_double(
        ActionDispatch::Request,
        remote_ip: "192.168.0.10",
        user_agent: "RSpec Browser"
      )

      audit_log = described_class.call(
        user: user,
        action: "users.create",
        auditable: user,
        request: request,
        metadata: { "changed_fields" => ["name"] }
      )

      expect(audit_log).to be_persisted
      expect(audit_log.user).to eq(user)
      expect(audit_log.action).to eq("users.create")
      expect(audit_log.auditable).to eq(user)
      expect(audit_log.ip_address).to eq("192.168.0.10")
      expect(audit_log.user_agent).to eq("RSpec Browser")
      expect(audit_log.metadata).to eq("changed_fields" => ["name"])
      expect(audit_log.occurred_at).to be_present
    end

    it "accepts request and metadata as optional arguments" do
      user = create(:user)

      audit_log = described_class.call(user: user, action: "auth.login")

      expect(audit_log).to be_persisted
      expect(audit_log.metadata).to eq({})
      expect(audit_log.ip_address).to be_nil
      expect(audit_log.user_agent).to be_nil
    end
  end
end
