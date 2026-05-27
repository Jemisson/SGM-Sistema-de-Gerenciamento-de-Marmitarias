require "swagger_helper"

RSpec.describe "API V1 Ingredients", type: :request do
  path "/api/v1/ingredients" do
    get "Lists ingredients" do
      tags "Ingredients"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :code, in: :query, type: :string, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false
      parameter name: :supplier_id, in: :query, type: :integer, required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :below_minimum_stock, in: :query, type: :boolean, required: false

      response "200", "ingredients listed" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:code) { nil }
        let(:category_id) { nil }
        let(:supplier_id) { nil }
        let(:active) { nil }
        let(:below_minimum_stock) { nil }

        before do
          create(:ingredient, name: "Arroz")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/ingredient" }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:code) { nil }
        let(:category_id) { nil }
        let(:supplier_id) { nil }
        let(:active) { nil }
        let(:below_minimum_stock) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:code) { nil }
        let(:category_id) { nil }
        let(:supplier_id) { nil }
        let(:active) { nil }
        let(:below_minimum_stock) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates an ingredient" do
      tags "Ingredients"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :ingredient_payload, in: :body, schema: { "$ref" => "#/components/schemas/ingredient_payload" }

      response "201", "ingredient created" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category) { create(:category) }
        let(:supplier) { create(:supplier) }
        let(:ingredient_payload) do
          {
            ingredient: {
              code: "INS-RSWAG",
              name: "Arroz",
              category_id: category.id,
              supplier_id: supplier.id,
              unit: "kg",
              current_stock: "10.500",
              minimum_stock: "2.000",
              purchase_price: "15.90"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/ingredient" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:ingredient_payload) { { ingredient: { code: "INS-X", name: "Arroz", unit: "kg" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:ingredient_payload) { { ingredient: { code: "INS-X", name: "Arroz", unit: "kg" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:ingredient_payload) { { ingredient: { code: "", name: "", unit: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/ingredients/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows an ingredient" do
      tags "Ingredients"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "ingredient found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/ingredient" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:ingredient).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "ingredient not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates an ingredient" do
      tags "Ingredients"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :ingredient_payload, in: :body, schema: { "$ref" => "#/components/schemas/ingredient_payload" }

      response "200", "ingredient updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }
        let(:ingredient_payload) { { ingredient: { name: "Arroz Atualizado" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/ingredient" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:ingredient).id }
        let(:ingredient_payload) { { ingredient: { name: "Arroz Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }
        let(:ingredient_payload) { { ingredient: { name: "Arroz Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "ingredient not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:ingredient_payload) { { ingredient: { name: "Arroz Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }
        let(:ingredient_payload) { { ingredient: { current_stock: "-1" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes an ingredient" do
      tags "Ingredients"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "ingredient disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/ingredient" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:ingredient).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:ingredient).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "ingredient not found" do
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
