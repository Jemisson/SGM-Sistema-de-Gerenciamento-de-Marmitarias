require "swagger_helper"

RSpec.describe "API V1 Stock Movements", type: :request do
  path "/api/v1/stock_movements" do
    get "Lists stock movements" do
      tags "Stock Movements"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :ingredient_id, in: :query, type: :integer, required: false
      parameter name: :movement_type, in: :query, type: :string, required: false, enum: StockMovement.movement_types.keys
      parameter name: :start_date, in: :query, type: :string, required: false, example: "2026-05-01T00:00:00Z"
      parameter name: :end_date, in: :query, type: :string, required: false, example: "2026-05-31T23:59:59Z"

      response "200", "stock movements listed" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:ingredient_id) { nil }
        let(:movement_type) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }

        before do
          create(:stock_movement, user: user)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/stock_movement" }
                 }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:ingredient_id) { nil }
        let(:movement_type) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:ingredient_id) { nil }
        let(:movement_type) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a stock movement" do
      tags "Stock Movements"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :stock_movement_payload, in: :body, schema: { "$ref" => "#/components/schemas/stock_movement_payload" }

      response "201", "stock movement created" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:ingredient) { create(:ingredient, current_stock: 10) }
        let(:stock_movement_payload) do
          {
            stock_movement: {
              ingredient_id: ingredient.id,
              movement_type: "entry",
              quantity: "5.000",
              unit_cost: "12.50",
              reason: "Compra"
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/stock_movement" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:stock_movement_payload) { { stock_movement: { ingredient_id: create(:ingredient).id, movement_type: "entry", quantity: "1.000" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:stock_movement_payload) { { stock_movement: { ingredient_id: create(:ingredient).id, movement_type: "entry", quantity: "1.000" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:stock_movement_payload) { { stock_movement: { ingredient_id: create(:ingredient).id, movement_type: "adjustment", quantity: "0" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/stock_movements/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a stock movement" do
      tags "Stock Movements"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "stock movement found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:stock_movement, user: user).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/stock_movement" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:stock_movement).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:stock_movement).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "stock movement not found" do
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
