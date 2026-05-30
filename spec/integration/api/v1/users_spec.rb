require "swagger_helper"

RSpec.describe "API V1 Users", type: :request do
  path "/api/v1/users" do
    get "Lists users" do
      tags "Users"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :email, in: :query, type: :string, required: false
      parameter name: :role, in: :query, type: :string, enum: %w[admin manager cashier], required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "users listed" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:email) { nil }
        let(:role) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:user, :manager, name: "Gerente SGM")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/user" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:email) { nil }
        let(:role) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:email) { nil }
        let(:role) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a user" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :user_payload, in: :body, schema: { "$ref" => "#/components/schemas/user_payload" }
      request_body_example(
        name: :admin,
        summary: "Administrador",
        value: {
          user: {
            name: "Administrador SGM",
            cpf: "33333333333",
            role: "admin",
            email: "novo.admin@example.com",
            password: "password123",
            password_confirmation: "password123",
            active: true
          }
        }
      )
      request_body_example(
        name: :manager,
        summary: "Gerente",
        value: {
          user: {
            name: "Gerente SGM",
            cpf: "44444444444",
            role: "manager",
            email: "novo.manager@example.com",
            password: "password123",
            password_confirmation: "password123",
            active: true
          }
        }
      )
      request_body_example(
        name: :cashier,
        summary: "Caixa",
        value: {
          user: {
            name: "Caixa SGM",
            cpf: "55555555555",
            role: "cashier",
            email: "novo.cashier@example.com",
            password: "password123",
            password_confirmation: "password123",
            active: true
          }
        }
      )

      response "201", "user created" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:user_payload) do
          {
            user: {
              name: "Caixa SGM",
              cpf: "55555555555",
              role: "cashier",
              email: "novo.cashier@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/user" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:user_payload) { { user: { name: "Caixa SGM" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:user_payload) { { user: { name: "Caixa SGM" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/users/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a user" do
      tags "Users"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "user found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:user, :cashier).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/user" }
               }

        run_test!
      end
    end

    patch "Updates a user" do
      tags "Users"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :user_payload, in: :body, schema: { "$ref" => "#/components/schemas/user_payload" }

      response "200", "user updated" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:user, :cashier).id }
        let(:user_payload) { { user: { name: "Caixa Atualizado", active: true } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/user" }
               }

        run_test!
      end
    end

    delete "Deactivates a user" do
      tags "Users"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "user deactivated" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:user, :cashier).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/user" }
               }

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
