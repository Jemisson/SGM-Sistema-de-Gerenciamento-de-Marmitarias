require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it "is valid with valid attributes" do
    expect(build(:audit_log)).to be_valid
  end

  it "requires an action" do
    audit_log = build(:audit_log, action: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:action]).to include("can't be blank")
  end

  it "requires occurred_at" do
    audit_log = build(:audit_log, occurred_at: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:occurred_at]).to include("can't be blank")
  end

  it "optionally belongs to an auditable record" do
    audit_log = build(:audit_log, auditable: nil)

    expect(audit_log).to be_valid
  end
end
