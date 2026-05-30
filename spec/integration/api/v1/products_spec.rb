require "swagger_helper"

RSpec.describe "API V1 Products", type: :request do
  path "/api/v1/products" do
    get "Lists active products" do
      tags "Products"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :code, in: :query, type: :string, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "products listed" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:code) { nil }
        let(:category_id) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:product, name: "Marmita de Frango")
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/product" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:code) { nil }
        let(:category_id) { nil }
        let(:active) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a product" do
      tags "Products"
      consumes "application/json", "multipart/form-data"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :product_payload, in: :body, schema: { "$ref" => "#/components/schemas/product_payload" }

      response "201", "product created" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category) { create(:category) }
        let(:product_payload) do
          {
            product: {
              code: "M001",
              name: "Marmita de Frango",
              description: "Arroz, feijao e frango",
              category_id: category.id,
              sale_price: "24.90"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/product" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:category) { create(:category) }
        let(:product_payload) do
          {
            product: {
              code: "M001",
              name: "Marmita de Frango",
              category_id: category.id,
              sale_price: "24.90"
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:category) { create(:category) }
        let(:product_payload) do
          {
            product: {
              code: "M001",
              name: "Marmita de Frango",
              category_id: category.id,
              sale_price: "24.90"
            }
          }
        end

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product_payload) { { product: { code: "", name: "", sale_price: "0" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/products/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a product" do
      tags "Products"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "product found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/product" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:product).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a product" do
      tags "Products"
      consumes "application/json", "multipart/form-data"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :product_payload, in: :body, schema: { "$ref" => "#/components/schemas/product_payload" }

      response "200", "product updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }
        let(:product_payload) { { product: { name: "Marmita Atualizada" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/product" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:product).id }
        let(:product_payload) { { product: { name: "Marmita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }
        let(:product_payload) { { product: { name: "Marmita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:product_payload) { { product: { name: "Marmita Atualizada" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }
        let(:product_payload) { { product: { name: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes a product" do
      tags "Products"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "product disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/product" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:product).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:product).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "product not found" do
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
