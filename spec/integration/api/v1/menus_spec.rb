require "swagger_helper"

RSpec.describe "API V1 Menus", type: :request do
  path "/api/v1/menus" do
    get "Lists menus" do
      tags "Menus"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :name, in: :query, type: :string, required: false
      parameter name: :status, in: :query, type: :string, enum: Menu.statuses.keys, required: false
      parameter name: :active, in: :query, type: :boolean, required: false
      parameter name: :date, in: :query, type: :string, format: :date, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "menus listed" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:name) { nil }
        let(:status) { nil }
        let(:active) { nil }
        let(:date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        before do
          create(:menu, status: :active)
        end

        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/menu" }
                 },
                 meta: { "$ref" => "#/components/schemas/pagination_meta" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:name) { nil }
        let(:status) { nil }
        let(:active) { nil }
        let(:date) { nil }
        let(:page) { nil }
        let(:per_page) { nil }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    post "Creates a menu" do
      tags "Menus"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :menu_payload, in: :body, schema: { "$ref" => "#/components/schemas/menu_payload" }

      response "201", "menu created" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:menu_payload) { valid_menu_payload(product) }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/menu" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:product) { create(:product) }
        let(:menu_payload) { valid_menu_payload(product) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:product) { create(:product) }
        let(:menu_payload) { valid_menu_payload(product) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:menu_payload) { { menu: { name: "", start_date: Date.current.iso8601, end_date: (Date.current - 1.day).iso8601 } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/menus/current" do
    get "Shows current active menu" do
      tags "Menus"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "current menu found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }

        before do
          create(:menu, status: :active, start_date: Date.current - 1.day, end_date: Date.current + 1.day)
        end

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/menu" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "current menu not found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  path "/api/v1/menus/{id}" do
    parameter name: :id, in: :path, type: :integer

    get "Shows a menu" do
      tags "Menus"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "menu found" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu, status: :active).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/menu" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:menu).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "menu not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    patch "Updates a menu" do
      tags "Menus"
      consumes "application/json"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :menu_payload, in: :body, schema: { "$ref" => "#/components/schemas/menu_payload" }

      response "200", "menu updated" do
        let(:user) { create(:user, :manager) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu).id }
        let(:menu_payload) { { menu: { name: "Cardapio Atualizado" } } }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/menu" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:menu).id }
        let(:menu_payload) { { menu: { name: "Cardapio Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu).id }
        let(:menu_payload) { { menu: { name: "Cardapio Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "menu not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }
        let(:menu_payload) { { menu: { name: "Cardapio Atualizado" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "422", "validation error" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu).id }
        let(:menu_payload) { { menu: { name: "" } } }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end

    delete "Soft deletes a menu" do
      tags "Menus"
      produces "application/json"
      security [bearerAuth: []]

      response "200", "menu disabled" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu).id }

        schema type: :object,
               properties: {
                 data: { "$ref" => "#/components/schemas/menu" }
               }

        run_test!
      end

      response "401", "missing or invalid token" do
        let(:Authorization) { "Bearer invalid-token" }
        let(:id) { create(:menu).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "403", "forbidden" do
        let(:user) { create(:user, :cashier) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { create(:menu).id }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end

      response "404", "menu not found" do
        let(:user) { create(:user, :admin) }
        let(:Authorization) { authorization_header_for(user) }
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/error_response"

        run_test!
      end
    end
  end

  def valid_menu_payload(product)
    {
      menu: {
        name: "Cardapio da Semana",
        start_date: Date.current.iso8601,
        end_date: (Date.current + 7.days).iso8601,
        status: "active",
        active: true,
        menu_items_attributes: [
          {
            product_id: product.id,
            available: true,
            price_override: "23.90"
          }
        ]
      }
    }
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    "Bearer #{token}"
  end
end
