require "rails_helper"

RSpec.describe "Api::V1::Reports", type: :request do
  describe "GET /api/v1/reports/overview" do
    it "returns overview for admins" do
      admin = create(:user, :admin)

      get "/api/v1/reports/overview", params: { period: "today" }, headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "total_revenue",
        "average_ticket",
        "gross_profit",
        "stock_items_count",
        "top_products"
      )
    end

    it "returns validation error for invalid period range" do
      manager = create(:user, :manager)

      get "/api/v1/reports/overview",
          params: { period: "custom", start_date: "2026-05-31", end_date: "2026-05-01" },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "base",
          "message" => "end_date can't be before start_date"
        }
      )
    end
  end

  describe "GET /api/v1/reports/statistics" do
    it "returns sales statistics for managers" do
      manager = create(:user, :manager)

      get "/api/v1/reports/statistics", params: { period: "month" }, headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "total_sold",
        "total_revenue",
        "average_ticket",
        "sales_by_payment_method",
        "sales_by_product"
      )
    end
  end

  describe "GET /api/v1/reports/stock" do
    it "returns stock report for managers" do
      manager = create(:user, :manager)

      get "/api/v1/reports/stock", params: { period: "week" }, headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "ingredients_below_minimum_stock",
        "ingredients_near_expiration",
        "total_ingredients",
        "stock_consumption_summary"
      )
    end
  end

  describe "GET /api/v1/reports/financial" do
    it "returns financial report for managers" do
      manager = create(:user, :manager)

      get "/api/v1/reports/financial", params: { period: "year" }, headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "incomes",
        "expenses",
        "balance",
        "totals_by_payment_method"
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/reports/financial", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/reports/financial"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
