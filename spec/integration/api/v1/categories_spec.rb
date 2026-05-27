require "swagger_helper"

RSpec.describe "API V1 Categories", type: :request do
  path "/api/v1/categories" do
    get "Lists active categories" do
      tags "Categories"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "categories listed" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:category, name: "Bebidas")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/category" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :category_payload, in: :body, schema: { "$ref" => "#/components/schemas/category_payload" }

      response "201", "category created" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category_payload) do
          {
            category: {
              name: "Marmitas",
              description: "Linha principal"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/category" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:category_payload) { { category: { name: "Marmitas" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category_payload) { { category: { name: "Marmitas" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category_payload) { { category: { name: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/categories/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a category" do
      tags "Categories"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "category found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/category" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:category).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "category not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :category_payload, in: :body, schema: { "$ref" => "#/components/schemas/category_payload" }

      response "200", "category updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }
        let(:category_payload) { { category: { name: "Atualizada" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/category" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:category).id }
        let(:category_payload) { { category: { name: "Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }
        let(:category_payload) { { category: { name: "Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "category not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:category_payload) { { category: { name: "Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }
        let(:category_payload) { { category: { name: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes a category" do
      tags "Categories"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "category disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/category" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:category).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:category).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "category not found" do
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
