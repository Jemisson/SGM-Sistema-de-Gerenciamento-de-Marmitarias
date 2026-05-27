require "swagger_helper"

RSpec.describe "API V1 Sales", type: :request do
  path "/api/v1/sales" do
    get "Lists sales" do
      tags "Sales"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "sales listed" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }

        before do
          create(:sale)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/sale" }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a sale" do
      tags "Sales"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :sale_payload, in: :body, schema: { "$ref" => "#/components/schemas/sale_payload" }

      response "201", "sale created" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:ingredient) { create(:ingredient, current_stock: 5) }
        let(:sale_payload) do
          create(:cash_session, opened_by: user)
          create_recipe_for(product, ingredient)
          {
            sale: {
              payment_method: "pix",
              sale_items_attributes: [
                {
                  product_id: product.id,
                  quantity: 1
                }
              ]
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/sale" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:sale_payload) { { sale: { payment_method: "pix", sale_items_attributes: [] } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:sale_payload) { { sale: { payment_method: "pix", sale_items_attributes: [] } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:sale_payload) { { sale: { payment_method: "pix", sale_items_attributes: [] } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/sales/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a sale" do
      tags "Sales"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "sale found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:sale).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/sale" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:sale).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "sale not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/sales/{id}/cancel" do
    parameter name: :id, in: :path, type: :integer

    patch "Cancels a sale" do
      tags "Sales"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "sale canceled" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:sale).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/sale" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:sale).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:sale).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "sale not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "already canceled" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:sale, :canceled).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  def create_recipe_for(product, ingredient)
    recipe = build(:recipe, product: product, items_count: 0)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient)
    recipe.save!
    recipe
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
