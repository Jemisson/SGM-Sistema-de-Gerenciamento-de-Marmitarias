require "swagger_helper"

RSpec.describe "API V1 Audit Logs", type: :request do
  path "/api/v1/audit_logs" do
    get "Lists audit logs" do
      tags "Audit Logs"
      produces "application/json"
      security [bearerAuth: []]

      parameter name: :user_id, in: :query, type: :integer, required: false
      parameter name: :action, in: :query, type: :string, required: false
      parameter name: :start_date, in: :query, type: :string, required: false, example: "2026-05-01T00:00:00Z"
      parameter name: :end_date, in: :query, type: :string, required: false, example: "2026-05-31T23:59:59Z"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "audit logs listed" do
        let(:admin) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(admin) }
        let(:user_id) { nil }
        let(:action) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:audit_log, user: admin, action: "auth.login")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/audit_log" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:user_id) { nil }
        let(:action) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:cashier) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(cashier) }
        let(:user_id) { nil }
        let(:action) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
