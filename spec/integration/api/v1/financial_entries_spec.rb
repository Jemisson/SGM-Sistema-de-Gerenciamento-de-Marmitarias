require "swagger_helper"

RSpec.describe "API V1 Financial Entries", type: :request do
  path "/api/v1/financial_entries" do
    get "Lists financial entries" do
      tags "Financial Entries"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :entry_type, in: :query, type: :string, enum: FinancialEntry.entry_types.keys, required: false
      parameter name: :payment_method, in: :query, type: :string, enum: FinancialEntry.payment_methods.keys, required: false
      parameter name: :category, in: :query, type: :string, required: false
      parameter name: :start_date, in: :query, type: :string, format: "date-time", required: false
      parameter name: :end_date, in: :query, type: :string, format: "date-time", required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "financial entries listed" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:entry_type) { nil }
        let(:payment_method) { nil }
        let(:category) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:financial_entry)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/financial_entry" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:entry_type) { nil }
        let(:payment_method) { nil }
        let(:category) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:entry_type) { nil }
        let(:payment_method) { nil }
        let(:category) { nil }
        let(:start_date) { nil }
        let(:end_date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a financial entry" do
      tags "Financial Entries"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :financial_entry_payload, in: :body, schema: { "$ref" => "#/components/schemas/financial_entry_payload" }

      response "201", "financial entry created" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:financial_entry_payload) do
          {
            financial_entry: {
              entry_type: "income",
              category: "Aporte",
              description: "Entrada manual",
              amount: "100.00",
              payment_method: "pix",
              occurred_at: Time.current.iso8601
            }
          }
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/financial_entry" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:financial_entry_payload) { { financial_entry: { entry_type: "income", amount: "100.00", payment_method: "pix", occurred_at: Time.current.iso8601 } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:financial_entry_payload) { { financial_entry: { entry_type: "income", amount: "100.00", payment_method: "pix", occurred_at: Time.current.iso8601 } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:financial_entry_payload) { { financial_entry: { entry_type: "expense", amount: "0", payment_method: "cash" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/financial_entries/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a financial entry" do
      tags "Financial Entries"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "financial entry found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/financial_entry" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:financial_entry).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "financial entry not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a financial entry" do
      tags "Financial Entries"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :financial_entry_payload, in: :body, schema: { "$ref" => "#/components/schemas/financial_entry_payload" }

      response "200", "financial entry updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry).id }
        let(:financial_entry_payload) { { financial_entry: { amount: "120.00" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/financial_entry" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:financial_entry).id }
        let(:financial_entry_payload) { { financial_entry: { amount: "120.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry, :from_sale).id }
        let(:financial_entry_payload) { { financial_entry: { amount: "120.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "financial entry not found" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:financial_entry_payload) { { financial_entry: { amount: "120.00" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Inactivates a financial entry" do
      tags "Financial Entries"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "financial entry inactivated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/financial_entry" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:financial_entry).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:financial_entry, :from_sale).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "financial entry not found" do
        let(:user) { create(:user, :manager) }
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
