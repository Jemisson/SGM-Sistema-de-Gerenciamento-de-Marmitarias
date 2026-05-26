require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let(:password) { "password123" }
  let(:user) { create(:user, password: password) }

  describe "POST /api/v1/auth/login" do
    it "authenticates an active user and returns a JWT" do
      expect do
        post "/api/v1/auth/login", params: {
          user: {
            email: user.email,
            password: password
          }
        }
      end.to change(AuditLog, :count).by(1)

      body = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to start_with("Bearer ")
      expect(body.dig("data", "token")).to be_present
      expect(body.dig("data", "user")).to include(
        "id" => user.id,
        "name" => user.name,
        "email" => user.email,
        "role" => user.role,
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: user,
        action: "auth.login",
        auditable: user
      )
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: {
        user: {
          email: user.email,
          password: "wrong-password"
        }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "base",
            "message" => "Credenciais inválidas."
          }
        ]
      )
    end

    it "rejects inactive users" do
      inactive_user = create(:user, :inactive, password: password)

      post "/api/v1/auth/login", params: {
        user: {
          email: inactive_user.email,
          password: password
        }
      }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "base",
            "message" => "Usuário inativo."
          }
        ]
      )
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the authenticated user" do
      get "/api/v1/auth/me", headers: authorization_header_for(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "user")).to include(
        "id" => user.id,
        "email" => user.email,
        "role" => user.role
      )
    end

    it "rejects requests without token" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "authorization",
            "message" => "Token ausente."
          }
        ]
      )
    end

    it "rejects requests with invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "authorization",
            "message" => "Token inválido."
          }
        ]
      )
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "invalidates the current token through jti" do
      headers = authorization_header_for(user)
      previous_jti = user.jti

      expect do
        delete "/api/v1/auth/logout", headers: headers
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "data" => {
          "message" => "Logout realizado com sucesso."
        }
      )
      expect(user.reload.jti).not_to eq(previous_jti)
      expect(AuditLog.last).to have_attributes(
        user: user,
        action: "auth.logout",
        auditable: user
      )

      get "/api/v1/auth/me", headers: headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "authorization",
            "message" => "Token inválido."
          }
        ]
      )
    end

    it "rejects requests without token" do
      delete "/api/v1/auth/logout"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "authorization",
            "message" => "Token ausente."
          }
        ]
      )
    end

    it "rejects requests with invalid token" do
      delete "/api/v1/auth/logout", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "authorization",
            "message" => "Token inválido."
          }
        ]
      )
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
