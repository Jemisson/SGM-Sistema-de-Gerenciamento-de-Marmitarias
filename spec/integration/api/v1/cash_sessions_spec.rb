require "swagger_helper"

RSpec.describe "API V1 Cash Sessions", type: :request do
  path "/api/v1/cash_sessions" do
    get "Lists cash sessions" do
      tags "Cash Sessions"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "cash sessions listed" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:cash_session)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/cash_session" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/cash_sessions/open" do
    post "Opens a cash session" do
      tags "Cash Sessions"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :cash_session_payload, in: :body, schema: { "$ref" => "#/components/schemas/cash_session_open_payload" }

      response "201", "cash session opened" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:cash_session_payload) do
          {
            cash_session: {
              opening_amount: "100.00",
              notes: "Inicio do turno"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/cash_session" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:cash_session_payload) { { cash_session: { opening_amount: "100.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:cash_session_payload) { { cash_session: { opening_amount: "100.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:cash_session_payload) { { cash_session: { opening_amount: "-1.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/cash_sessions/current" do
    get "Shows current opened cash session" do
      tags "Cash Sessions"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "current cash session found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }

        before do
          create(:cash_session, opened_by: user)
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/cash_session" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "current cash session not found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/cash_sessions/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a cash session" do
      tags "Cash Sessions"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "cash session found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:cash_session).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/cash_session" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:cash_session).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "cash session not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/cash_sessions/{id}/close" do
    parameter name: :id, in: :path, type: :integer

    patch "Closes a cash session" do
      tags "Cash Sessions"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :cash_session_payload, in: :body, schema: { "$ref" => "#/components/schemas/cash_session_close_payload" }

      response "200", "cash session closed" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:cash_session).id }
        let(:cash_session_payload) { { cash_session: { closing_amount: "100.00" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/cash_session" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:cash_session).id }
        let(:cash_session_payload) { { cash_session: { closing_amount: "100.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:cash_session).id }
        let(:cash_session_payload) { { cash_session: { closing_amount: "100.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "cash session not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:cash_session_payload) { { cash_session: { closing_amount: "100.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:cash_session).id }
        let(:cash_session_payload) { { cash_session: { closing_amount: nil } } }

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
