require "swagger_helper"

RSpec.describe "API V1 Reports", type: :request do
  shared_examples "report authorization errors" do
    response "401", "missing or invalid token" do
      let(:Authorization) { "Bearer invalid-token" }
      let(:period) { nil }
      let(:start_date) { nil }
      let(:end_date) { nil }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end

    response "403", "forbidden" do
      let(:user) { create(:user, :cashier) }
      let(:Authorization) { authorization_header_for(user) }
      let(:period) { nil }
      let(:start_date) { nil }
      let(:end_date) { nil }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end

    response "422", "invalid period" do
      let(:user) { create(:user, :manager) }
      let(:Authorization) { authorization_header_for(user) }
      let(:period) { "custom" }
      let(:start_date) { "2026-05-31" }
      let(:end_date) { "2026-05-01" }

      schema "$ref" => "#/components/schemas/error_response"

      run_test!
    end
  end

  path "/api/v1/reports/overview" do
    get "Shows overview report" do
      tags "Reports"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :period, in: :query, type: :string, enum: Reports::PeriodRange::VALID_PERIODS, required: false
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false

      response "200", "overview report" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:period) { "month" }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     total_revenue: { type: :string },
                     average_ticket: { type: :string },
                     gross_profit: { type: :string },
                     stock_items_count: { type: :integer },
                     top_products: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/report_product_summary" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "report authorization errors"
    end
  end

  path "/api/v1/reports/statistics" do
    get "Shows sales statistics report" do
      tags "Reports"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :period, in: :query, type: :string, enum: Reports::PeriodRange::VALID_PERIODS, required: false
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false

      response "200", "statistics report" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:period) { "month" }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     total_sold: { type: :integer },
                     total_revenue: { type: :string },
                     average_ticket: { type: :string },
                     sales_by_payment_method: { type: :object },
                     sales_by_product: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/report_product_summary" }
                     }
                   }
                 }
               }

        run_test!
      end

      include_examples "report authorization errors"
    end
  end

  path "/api/v1/reports/stock" do
    get "Shows stock report" do
      tags "Reports"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :period, in: :query, type: :string, enum: Reports::PeriodRange::VALID_PERIODS, required: false
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false

      response "200", "stock report" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:period) { "month" }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     ingredients_below_minimum_stock: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/report_ingredient_summary" }
                     },
                     ingredients_near_expiration: {
                       type: :array,
                       items: { "$ref" => "#/components/schemas/report_ingredient_summary" }
                     },
                     total_ingredients: { type: :integer },
                     stock_consumption_summary: { type: :array, items: { type: :object } }
                   }
                 }
               }

        run_test!
      end

      include_examples "report authorization errors"
    end
  end

  path "/api/v1/reports/financial" do
    get "Shows financial report" do
      tags "Reports"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :period, in: :query, type: :string, enum: Reports::PeriodRange::VALID_PERIODS, required: false
      parameter name: :start_date, in: :query, type: :string, format: "date", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date", required: false

      response "200", "financial report" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:period) { "month" }
        let(:start_date) { nil }
        let(:end_date) { nil }

        schema type: :object,
               properties: {
                 data: {
                   type: :object,
                   properties: {
                     period: { "$ref" => "#/components/schemas/report_period" },
                     incomes: { type: :string },
                     expenses: { type: :string },
                     balance: { type: :string },
                     totals_by_payment_method: { type: :object }
                   }
                 }
               }

        run_test!
      end

      include_examples "report authorization errors"
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
