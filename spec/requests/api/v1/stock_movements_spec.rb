require "rails_helper"

RSpec.describe "Api::V1::StockMovements", type: :request do
  describe "GET /api/v1/stock_movements" do
    it "lists stock movements for admins" do
      admin = create(:user, :admin)
      movement = create(:stock_movement, user: admin, movement_type: :entry)

      get "/api/v1/stock_movements", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").first).to include(
        "id" => movement.id,
        "movement_type" => "entry",
        "quantity" => "5.0"
      )
    end

    it "filters by ingredient, movement type and period" do
      manager = create(:user, :manager)
      ingredient = create(:ingredient)
      included_movement = create(
        :stock_movement,
        ingredient: ingredient,
        movement_type: :exit,
        occurred_at: Time.zone.local(2026, 5, 20, 12, 0, 0)
      )
      create(:stock_movement, ingredient: ingredient, movement_type: :entry, occurred_at: Time.zone.local(2026, 5, 20, 12, 10, 0))
      create(:stock_movement, movement_type: :exit, occurred_at: Time.zone.local(2026, 5, 21, 12, 0, 0))

      get "/api/v1/stock_movements",
          params: {
            ingredient_id: ingredient.id,
            movement_type: "exit",
            start_date: "2026-05-20T00:00:00Z",
            end_date: "2026-05-20T23:59:59Z"
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_movement.id])
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/stock_movements", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/stock_movements"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/stock_movements/:id" do
    it "shows a stock movement for managers" do
      manager = create(:user, :manager)
      movement = create(:stock_movement, user: manager)

      get "/api/v1/stock_movements/#{movement.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => movement.id,
        "movement_type" => movement.movement_type,
        "quantity" => movement.quantity.to_s
      )
      expect(response.parsed_body.dig("data", "ingredient")).to include(
        "id" => movement.ingredient_id,
        "code" => movement.ingredient.code,
        "name" => movement.ingredient.name
      )
    end

    it "returns 404 when stock movement does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/stock_movements/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/stock_movements" do
    it "creates an entry for admins, updates stock and registers an audit log" do
      admin = create(:user, :admin)
      ingredient = create(:ingredient, current_stock: 10)

      expect do
        post "/api/v1/stock_movements",
             params: {
               stock_movement: {
                 ingredient_id: ingredient.id,
                 movement_type: "entry",
                 quantity: "5.000",
                 unit_cost: "12.50",
                 reason: "Compra"
               }
             },
             headers: authorization_header_for(admin)
      end.to change(StockMovement, :count).by(1)
        .and change(AuditLog, :count).by(1)

      movement = StockMovement.last

      expect(response).to have_http_status(:created)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("15.0"))
      expect(response.parsed_body.fetch("data")).to include(
        "id" => movement.id,
        "movement_type" => "entry",
        "quantity" => "5.0",
        "unit_cost" => "12.5"
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "stock_movements.create",
        auditable: movement
      )
    end

    it "creates an adjustment for managers and sets stock to the counted quantity" do
      manager = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 10)

      post "/api/v1/stock_movements",
           params: {
             stock_movement: {
               ingredient_id: ingredient.id,
               movement_type: "adjustment",
               quantity: "7.000",
               reason: "Contagem física"
             }
           },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("7.0"))
    end

    it "does not allow stock to become negative" do
      manager = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 2)

      expect do
        post "/api/v1/stock_movements",
             params: {
               stock_movement: {
                 ingredient_id: ingredient.id,
                 movement_type: "exit",
                 quantity: "3.000",
                 reason: "Uso manual"
               }
             },
             headers: authorization_header_for(manager)
      end.not_to change(StockMovement, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("2.0"))
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "quantity",
          "message" => "would make stock negative"
        }
      )
    end

    it "returns validation errors" do
      admin = create(:user, :admin)
      ingredient = create(:ingredient)

      post "/api/v1/stock_movements",
           params: {
             stock_movement: {
               ingredient_id: ingredient.id,
               movement_type: "adjustment",
               quantity: "0"
             }
           },
           headers: authorization_header_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "quantity",
          "message" => "must be greater than 0"
        },
        {
          "field" => "reason",
          "message" => "can't be blank"
        }
      )
    end

    it "returns validation error for unknown movement type" do
      admin = create(:user, :admin)
      ingredient = create(:ingredient)

      post "/api/v1/stock_movements",
           params: {
             stock_movement: {
               ingredient_id: ingredient.id,
               movement_type: "unknown",
               quantity: "1.000"
             }
           },
           headers: authorization_header_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "movement_type",
          "message" => "is not included in the list"
        }
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      ingredient = create(:ingredient)

      post "/api/v1/stock_movements",
           params: {
             stock_movement: {
               ingredient_id: ingredient.id,
               movement_type: "entry",
               quantity: "1.000"
             }
           },
           headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
