require "swagger_helper"

RSpec.describe "API V1 Password Recovery", type: :request do
  path "/api/v1/auth/password" do
    post "Requests password reset instructions" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :password_request, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: "caixa@sgm.test" }
            },
            required: %w[email]
          }
        },
        required: %w[user]
      }

      response "200", "request accepted" do
        let(:password_request) do
          {
            user: {
              email: "nao-revela@sgm.test"
            }
          }
        end

        schema "$ref" => "#/components/schemas/message_response"

        run_test!
      end

      response "422", "missing email" do
        let(:password_request) do
          {
            user: {
              email: ""
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Resets password using a recovery token" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :password_reset, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              reset_password_token: { type: :string },
              password: { type: :string, example: "new-password" },
              password_confirmation: { type: :string, example: "new-password" }
            },
            required: %w[reset_password_token password password_confirmation]
          }
        },
        required: %w[user]
      }

      response "200", "password reset" do
        let(:user) { create(:user) }
        let(:password_reset) do
          {
            user: {
              reset_password_token: user.send(:set_reset_password_token),
              password: "new-password",
              password_confirmation: "new-password"
            }
          }
        end

        schema "$ref" => "#/components/schemas/message_response"

        run_test!
      end

      response "422", "invalid reset data" do
        let(:password_reset) do
          {
            user: {
              reset_password_token: "",
              password: "",
              password_confirmation: ""
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end
end
