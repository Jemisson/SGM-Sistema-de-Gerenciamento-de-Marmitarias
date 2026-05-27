require "rails_helper"

RSpec.describe "Api::V1::Sales", type: :request do
  describe "GET /api/v1/sales" do
    it "lists sales for managers" do
      manager = create(:user, :manager)
      sale = create(:sale)

      get "/api/v1/sales", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([sale.id])
    end

    it "lists only own sales for cashiers" do
      cashier = create(:user, :cashier)
      own_sale = create(:sale, user: cashier)
      create(:sale)

      get "/api/v1/sales", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([own_sale.id])
    end

    it "forbids admins" do
      admin = create(:user, :admin)

      get "/api/v1/sales", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/sales/:id" do
    it "shows a sale" do
      cashier = create(:user, :cashier)
      sale = create(:sale, user: cashier)

      get "/api/v1/sales/#{sale.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => sale.id,
        "payment_method" => sale.payment_method,
        "status" => "confirmed",
        "total_amount" => sale.total_amount.to_s
      )
    end

    it "does not show another cashier sale" do
      cashier = create(:user, :cashier)
      sale = create(:sale)

      get "/api/v1/sales/#{sale.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/sales" do
    it "creates a sale, moves cash, consumes stock and registers audit log" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product, sale_price: 20)
      ingredient = create(:ingredient, current_stock: 5)
      create_recipe_for(product, ingredient, quantity: 0.500)

      expect do
        post "/api/v1/sales",
             params: {
               sale: {
                 payment_method: "pix",
                 total_amount: "1.00",
                 sale_items_attributes: [
                   {
                     product_id: product.id,
                     quantity: 2,
                     unit_price: "1.00",
                     total_price: "1.00"
                   }
                 ]
               }
             },
             headers: authorization_header_for(cashier),
             as: :json
      end.to change(Sale, :count).by(1)
        .and change(SaleItem, :count).by(1)
        .and change(CashMovement, :count).by(1)
        .and change(StockMovement, :count).by(1)
        .and change(AuditLog, :count).by(1)

      sale = Sale.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => sale.id,
        "payment_method" => "pix",
        "total_amount" => "40.0",
        "status" => "confirmed"
      )
      expect(response.parsed_body.dig("data", "sale_items").first).to include(
        "quantity" => 2,
        "unit_price" => "20.0",
        "total_price" => "40.0"
      )
      expect(ingredient.reload.current_stock).to eq(BigDecimal("4.000"))
      expect(AuditLog.last).to have_attributes(
        user: cashier,
        action: "sales.create",
        auditable: sale
      )
    end

    it "allows managers to create sale using an informed opened cash session" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session)
      product = create(:product)
      ingredient = create(:ingredient, current_stock: 5)
      create_recipe_for(product, ingredient)

      post "/api/v1/sales",
           params: {
             sale: {
               cash_session_id: cash_session.id,
               payment_method: "cash",
               sale_items_attributes: [{ product_id: product.id, quantity: 1 }]
             }
           },
           headers: authorization_header_for(manager),
           as: :json

      expect(response).to have_http_status(:created)
      expect(Sale.last.cash_session).to eq(cash_session)
    end

    it "requires an opened cash session" do
      cashier = create(:user, :cashier)
      product = create(:product)

      post "/api/v1/sales",
           params: {
             sale: {
               payment_method: "cash",
               sale_items_attributes: [{ product_id: product.id, quantity: 1 }]
             }
           },
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "cash_session",
          "message" => "must be opened"
        }
      )
    end

    it "requires product recipe" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product)

      post "/api/v1/sales",
           params: {
             sale: {
               payment_method: "cash",
               sale_items_attributes: [{ product_id: product.id, quantity: 1 }]
             }
           },
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "product",
          "message" => "must have an active recipe"
        }
      )
    end

    it "does not create sale when stock is insufficient" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product)
      ingredient = create(:ingredient, current_stock: 0.250)
      create_recipe_for(product, ingredient, quantity: 0.500)

      expect do
        post "/api/v1/sales",
             params: {
               sale: {
                 payment_method: "cash",
                 sale_items_attributes: [{ product_id: product.id, quantity: 1 }]
               }
             },
             headers: authorization_header_for(cashier),
             as: :json
      end.not_to change(Sale, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("0.250"))
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "quantity",
          "message" => "would make stock negative"
        }
      )
    end

    it "forbids admins" do
      admin = create(:user, :admin)

      post "/api/v1/sales",
           params: { sale: { payment_method: "cash", sale_items_attributes: [] } },
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/sales/:id/cancel" do
    it "cancels a sale and registers audit log without restoring stock" do
      cashier = create(:user, :cashier)
      sale = create(:sale, user: cashier)

      expect do
        patch "/api/v1/sales/#{sale.id}/cancel", headers: authorization_header_for(cashier)
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(sale.reload).to be_canceled
      expect(AuditLog.last).to have_attributes(
        user: cashier,
        action: "sales.cancel",
        auditable: sale
      )
    end

    it "does not cancel an already canceled sale" do
      cashier = create(:user, :cashier)
      sale = create(:sale, :canceled, user: cashier)

      patch "/api/v1/sales/#{sale.id}/cancel", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "status",
          "message" => "is already canceled"
        }
      )
    end
  end

  def create_recipe_for(product, ingredient, quantity: 0.250)
    recipe = build(:recipe, product: product, items_count: 0)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient, quantity: quantity)
    recipe.save!
    recipe
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
