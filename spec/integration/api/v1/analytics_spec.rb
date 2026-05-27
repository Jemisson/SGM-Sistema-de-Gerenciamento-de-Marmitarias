require "swagger_helper"

RSpec.describe "API V1 Analytics", type: :request do
  shared_examples "analytics authorization errors" do
    response "401", "missing or invalid token" do
      let(:Authorization) { "Bearer invalid-token" }
      let(:start_date) { nil }
      let(:end_date) { nil }
      let(:product_id) { nil }
      let(:category_id) { nil }
      let(:granularity) { nil }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end

    response "403", "forbidden" do
      let(:user) { create(:user, :cashier) }
      let(:Authorization) { authorization_header_for(user) }
      let(:start_date) { nil }
      let(:end_date) { nil }
      let(:product_id) { nil }
      let(:category_id) { nil }
      let(:granularity) { nil }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end

    response "422", "invalid period" do
      let(:user) { create(:user, :manager) }
      let(:Authorization) { authorization_header_for(user) }
      let(:start_date) { "2026-05-31" }
      let(:end_date) { "2026-05-01" }
      let(:product_id) { nil }
      let(:category_id) { nil }
      let(:granularity) { nil }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end
  end

  path "/api/v1/analytics/abc" do
    get "Shows ABC curve analytics" do
      tags "Analytics"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false

      response "200", "abc analytics" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:product_id) { nil }
        let(:category_id) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     total_revenue: { type: :string },
                     products: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/analytics_product_metric" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "analytics authorization errors"
    end
  end

  path "/api/v1/analytics/profitability" do
    get "Shows profitability analytics" do
      tags "Analytics"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false

      response "200", "profitability analytics" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:product_id) { nil }
        let(:category_id) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     products: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/analytics_product_metric" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "analytics authorization errors"
    end
  end

  path "/api/v1/analytics/trends" do
    get "Shows trend analytics" do
      tags "Analytics"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false
      parameter name: :granularity, in: :query, type: :string, enum: Analytics::TrendService::VALID_GRANULARITIES, required: false

      response "200", "trend analytics" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:product_id) { nil }
        let(:category_id) { nil }
        let(:granularity) { "day" }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     granularity: { type: :string },
                     points: { type: :array, items: { type: :object } }
                   }
                 }
               }

        run_test!
      end

      include_examples "analytics authorization errors"
    end
  end

  path "/api/v1/analytics/product_performance" do
    get "Shows product performance analytics" do
      tags "Analytics"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false

      response "200", "product performance analytics" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:product_id) { nil }
        let(:category_id) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     most_sold_products: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/analytics_product_metric" }
                     },
                     least_sold_products: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/analytics_product_metric" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "analytics authorization errors"
    end
  end

  path "/api/v1/analytics/ingredient_consumption" do
    get "Shows ingredient consumption analytics" do
      tags "Analytics"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false
      parameter name: :product_id, in: :query, type: :integer, required: false
      parameter name: :category_id, in: :query, type: :integer, required: false

      response "200", "ingredient consumption analytics" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:product_id) { nil }
        let(:category_id) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     ingredients: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/analytics_ingredient_metric" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "analytics authorization errors"
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
