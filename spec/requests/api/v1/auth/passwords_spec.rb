require "rails_helper"

RSpec.describe "Api::V1::Auth::Passwords", type: :request do
  include ActiveJob::TestHelper

  before do
    clear_enqueued_jobs
    ActiveJob::Base.queue_adapter = :test
  end

  describe "POST /api/v1/auth/password" do
    it "generates a reset token and enqueues reset instructions" do
      user = create(:user)

      expect do
        post "/api/v1/auth/password", params: {
          user: {
            email: user.email
          }
        }
      end.to have_enqueued_mail(UserMailer, :reset_password_instructions)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "data" => {
          "message" => "Se o e-mail estiver cadastrado, as instruções de recuperação serão enviadas."
        }
      )
      expect(user.reload.reset_password_token).to be_present
      expect(user.reset_password_sent_at).to be_present
    end

    it "does not reveal whether the email exists" do
      expect do
        post "/api/v1/auth/password", params: {
          user: {
            email: "nao-existe@sgm.test"
          }
        }
      end.not_to have_enqueued_mail(UserMailer, :reset_password_instructions)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "data" => {
          "message" => "Se o e-mail estiver cadastrado, as instruções de recuperação serão enviadas."
        }
      )
    end

    it "requires an email" do
      post "/api/v1/auth/password", params: {
        user: {
          email: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "email",
            "message" => "não pode ficar em branco"
          }
        ]
      )
    end
  end

  describe "PATCH /api/v1/auth/password" do
    it "resets the password and invalidates previous JWTs" do
      user = create(:user, password: "old-password")
      headers = authorization_header_for(user)
      token = user.send(:set_reset_password_token)
      previous_jti = user.jti

      patch "/api/v1/auth/password", params: {
        user: {
          reset_password_token: token,
          password: "new-password",
          password_confirmation: "new-password"
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "data" => {
          "message" => "Senha redefinida com sucesso."
        }
      )
      expect(user.reload.valid_password?("new-password")).to be(true)
      expect(user.jti).not_to eq(previous_jti)

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

    it "requires token, password and confirmation" do
      patch "/api/v1/auth/password", params: {
        user: {
          reset_password_token: "",
          password: "",
          password_confirmation: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "reset_password_token",
            "message" => "não pode ficar em branco"
          },
          {
            "field" => "password",
            "message" => "não pode ficar em branco"
          },
          {
            "field" => "password_confirmation",
            "message" => "não pode ficar em branco"
          }
        ]
      )
    end

    it "requires minimum password length" do
      token = create(:user).send(:set_reset_password_token)

      patch "/api/v1/auth/password", params: {
        user: {
          reset_password_token: token,
          password: "12345",
          password_confirmation: "12345"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "password",
            "message" => "deve ter no mínimo 6 caracteres"
          }
        ]
      )
    end

    it "requires password confirmation to match password" do
      token = create(:user).send(:set_reset_password_token)

      patch "/api/v1/auth/password", params: {
        user: {
          reset_password_token: token,
          password: "new-password",
          password_confirmation: "different-password"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "password_confirmation",
            "message" => "deve ser igual à senha"
          }
        ]
      )
    end

    it "rejects invalid reset tokens" do
      patch "/api/v1/auth/password", params: {
        user: {
          reset_password_token: "invalid-token",
          password: "new-password",
          password_confirmation: "new-password"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "reset_password_token",
          "message" => "is invalid"
        }
      )
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
