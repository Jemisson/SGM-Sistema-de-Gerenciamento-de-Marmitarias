require "swagger_helper"

RSpec.describe "API V1 Authentication", type: :request do
  path "/api/v1/auth/login" do
    post "Authenticates a user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :credentials, in: :body, schema: { "$ref" => "#/components/schemas/login_payload" }

      response "200", "authenticated" do
        let!(:user) { create(:user, email: "caixa@sgm.test", password: "password123") }
        let(:credentials) do
          {
            user: {
              email: user.email,
              password: "password123"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     user: { "$ref" => "#/components/schemas/user" },
                     token: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response "401", "invalid credentials" do
        let!(:user) { create(:user, email: "login-invalido@sgm.test", password: "password123") }
        let(:credentials) do
          {
            user: {
              email: user.email,
              password: "wrong-password"
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/auth/logout" do
    delete "Logs out the current user" do
      tags "Auth"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "logged out" do
        let(:user) { create(:user) }
        let(:Authorization) { authorization_header_for(user) }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     message: { type: :string }
                   }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Returns the authenticated user" do
      tags "Auth"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "authenticated user" do
        let(:user) { create(:user) }
        let(:Authorization) { authorization_header_for(user) }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     user: { "$ref" => "#/components/schemas/user" }
                   }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }

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
