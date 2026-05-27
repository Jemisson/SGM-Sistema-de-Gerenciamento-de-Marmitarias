require "rails_helper"

RSpec.describe "Api::V1::Analytics", type: :request do
  describe "GET /api/v1/analytics/abc" do
    it "returns ABC curve for admins" do
      admin = create(:user, :admin)

      get "/api/v1/analytics/abc", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "period",
        "total_revenue",
        "products"
      )
    end

    it "validates period" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/abc",
          params: { start_date: "2026-05-31", end_date: "2026-05-01" },
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

  describe "GET /api/v1/analytics/profitability" do
    it "returns profitability for managers" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/profitability", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include("period", "products")
    end
  end

  describe "GET /api/v1/analytics/trends" do
    it "returns trends for managers" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/trends", params: { granularity: "month" }, headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include("period", "points")
      expect(response.parsed_body.fetch("data")).to include("granularity" => "month")
    end

    it "validates granularity" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/trends", params: { granularity: "hour" }, headers: authorization_header_for(manager)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "base",
          "message" => "granularity is invalid"
        }
      )
    end
  end

  describe "GET /api/v1/analytics/product_performance" do
    it "returns product performance for managers" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/product_performance", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include("period", "most_sold_products", "least_sold_products")
    end
  end

  describe "GET /api/v1/analytics/ingredient_consumption" do
    it "returns ingredient consumption for managers" do
      manager = create(:user, :manager)

      get "/api/v1/analytics/ingredient_consumption", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include("period", "ingredients")
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/analytics/ingredient_consumption", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/analytics/ingredient_consumption"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
