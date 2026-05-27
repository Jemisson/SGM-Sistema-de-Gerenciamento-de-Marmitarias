require "swagger_helper"

RSpec.describe "API V1 Recipes", type: :request do
  path "/api/v1/recipes" do
    get "Lists active recipes" do
      tags "Recipes"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :active, in: :query, type: :boolean, required: false

      response "200", "recipes listed" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:product_id) { nil }
        let(:active) { nil }

        before do
          create(:recipe, name: "Receita Marmita de Frango")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/recipe" }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:product_id) { nil }
        let(:active) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:product_id) { nil }
        let(:active) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a recipe" do
      tags "Recipes"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :recipe_payload, in: :body, schema: { "$ref" => "#/components/schemas/recipe_payload" }

      response "201", "recipe created" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:ingredient) { create(:ingredient) }
        let(:recipe_payload) do
          {
            recipe: {
              product_id: product.id,
              name: "Receita Marmita de Frango",
              description: "Composicao padrao",
              recipe_items_attributes: [
                {
                  ingredient_id: ingredient.id,
                  quantity: "0.250",
                  unit: "kg"
                }
              ]
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/recipe" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:product) { create(:product) }
        let(:ingredient) { create(:ingredient) }
        let(:recipe_payload) { valid_recipe_payload(product, ingredient) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:ingredient) { create(:ingredient) }
        let(:recipe_payload) { valid_recipe_payload(product, ingredient) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:recipe_payload) do
          {
            recipe: {
              product_id: product.id,
              name: "",
              recipe_items_attributes: []
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/recipes/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a recipe" do
      tags "Recipes"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "recipe found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/recipe" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:recipe).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "recipe not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a recipe" do
      tags "Recipes"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :recipe_payload, in: :body, schema: { "$ref" => "#/components/schemas/recipe_payload" }

      response "200", "recipe updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }
        let(:recipe_payload) { { recipe: { name: "Receita Atualizada" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/recipe" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:recipe).id }
        let(:recipe_payload) { { recipe: { name: "Receita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }
        let(:recipe_payload) { { recipe: { name: "Receita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "recipe not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:recipe_payload) { { recipe: { name: "Receita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }
        let(:recipe_payload) { { recipe: { name: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes a recipe" do
      tags "Recipes"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "recipe disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/recipe" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:recipe).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:recipe).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "recipe not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  def valid_recipe_payload(product, ingredient)
    {
      recipe: {
        product_id: product.id,
        name: "Receita Marmita",
        recipe_items_attributes: [
          {
            ingredient_id: ingredient.id,
            quantity: "0.250",
            unit: "kg"
          }
        ]
      }
    }
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
