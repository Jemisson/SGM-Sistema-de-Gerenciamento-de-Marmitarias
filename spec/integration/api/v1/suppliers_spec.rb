require "swagger_helper"

RSpec.describe "API V1 Suppliers", type: :request do
  path "/api/v1/suppliers" do
    get "Lists suppliers" do
      tags "Suppliers"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :cnpj, in: :query, type: :string, required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "suppliers listed" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:cnpj) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:supplier, name: "Fornecedor Central")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/supplier" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:cnpj) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:cnpj) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a supplier" do
      tags "Suppliers"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :supplier_payload, in: :body, schema: { "$ref" => "#/components/schemas/supplier_payload" }

      response "201", "supplier created" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:supplier_payload) do
          {
            supplier: {
              name: "Fornecedor Central",
              cnpj: "12345678000199",
              email: "central@sgm.test",
              state: "PR"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/supplier" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:supplier_payload) { { supplier: { name: "Fornecedor", cnpj: "12345678000199" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:supplier_payload) { { supplier: { name: "Fornecedor", cnpj: "12345678000199" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:supplier_payload) { { supplier: { name: "", cnpj: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/suppliers/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a supplier" do
      tags "Suppliers"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "supplier found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/supplier" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:supplier).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "supplier not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a supplier" do
      tags "Suppliers"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :supplier_payload, in: :body, schema: { "$ref" => "#/components/schemas/supplier_payload" }

      response "200", "supplier updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }
        let(:supplier_payload) { { supplier: { name: "Fornecedor Atualizado" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/supplier" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:supplier).id }
        let(:supplier_payload) { { supplier: { name: "Fornecedor Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }
        let(:supplier_payload) { { supplier: { name: "Fornecedor Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "supplier not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:supplier_payload) { { supplier: { name: "Fornecedor Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }
        let(:supplier_payload) { { supplier: { email: "invalid-email" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes a supplier" do
      tags "Suppliers"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "supplier disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/supplier" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:supplier).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:supplier).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "supplier not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

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
