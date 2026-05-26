require "rails_helper"

RSpec.describe "Api::V1::AuditLogs", type: :request do
  describe "GET /api/v1/audit_logs" do
    it "allows admins to list audit logs" do
      admin = create(:user, :admin)
      audit_log = create(:audit_log, user: admin, action: "auth.login")

      get "/api/v1/audit_logs", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", 0)).to include(
        "id" => audit_log.id,
        "action" => "auth.login"
      )
    end

    it "allows managers to list audit logs" do
      manager = create(:user, :manager)
      create(:audit_log, user: manager, action: "cash_register.close")

      get "/api/v1/audit_logs", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").size).to eq(1)
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/audit_logs", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "filters by user, action and period" do
      admin = create(:user, :admin)
      user = create(:user, :cashier)
      included_log = create(
        :audit_log,
        user: user,
        action: "auth.login",
        occurred_at: Time.zone.local(2026, 5, 20, 12, 0, 0)
      )
      create(:audit_log, user: user, action: "auth.logout", occurred_at: Time.zone.local(2026, 5, 20, 12, 10, 0))
      create(:audit_log, action: "auth.login", occurred_at: Time.zone.local(2026, 5, 21, 12, 0, 0))

      get "/api/v1/audit_logs",
          params: {
            user_id: user.id,
            action: "auth.login",
            start_date: "2026-05-20T00:00:00Z",
            end_date: "2026-05-20T23:59:59Z"
          },
          headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_log.id])
    end

    it "paginates results" do
      admin = create(:user, :admin)
      create_list(:audit_log, 3, user: admin)

      get "/api/v1/audit_logs",
          params: { page: 2, per_page: 2 },
          headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").size).to eq(1)
      expect(response.parsed_body.fetch("meta")).to include(
        "page" => 2,
        "per_page" => 2,
        "total_count" => 3,
        "total_pages" => 2
      )
    end

    it "requires authentication" do
      get "/api/v1/audit_logs"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
