require "rails_helper"

RSpec.describe "Api::V1::Menus", type: :request do
  describe "GET /api/v1/menus" do
    it "lists only enabled menus by default for admins" do
      admin = create(:user, :admin)
      menu = create(:menu, name: "Semana Atual")
      create(:menu, :disabled, name: "Removido")

      get "/api/v1/menus", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([menu.id])
    end

    it "filters by name, status, active and date" do
      manager = create(:user, :manager)
      included_menu = create(
        :menu,
        :disabled,
        name: "Cardapio Semana",
        status: :inactive,
        start_date: Date.current - 1.day,
        end_date: Date.current + 1.day
      )
      create(:menu, :disabled, name: "Cardapio Semana", status: :draft)
      create(:menu, name: "Outro")

      get "/api/v1/menus",
          params: {
            name: "Semana",
            status: "inactive",
            active: false,
            date: Date.current.iso8601
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_menu.id])
    end

    it "allows cashiers to list active menus only" do
      cashier = create(:user, :cashier)
      active_menu = create(:menu, status: :active)
      create(:menu, :draft)
      create(:menu, :disabled, status: :active)

      get "/api/v1/menus", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_menu.id])
    end

    it "requires authentication" do
      get "/api/v1/menus"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/menus/current" do
    it "returns the active menu for the current date" do
      cashier = create(:user, :cashier)
      current_menu = create(:menu, start_date: Date.current - 1.day, end_date: Date.current + 1.day, status: :active)
      create(:menu, start_date: Date.current - 4.days, end_date: Date.current - 2.days, status: :active)

      get "/api/v1/menus/current", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(current_menu.id)
    end

    it "returns 404 when there is no current menu" do
      cashier = create(:user, :cashier)
      create(:menu, start_date: Date.current - 4.days, end_date: Date.current - 2.days, status: :active)

      get "/api/v1/menus/current", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/menus/:id" do
    it "shows a menu for cashiers" do
      cashier = create(:user, :cashier)
      menu = create(:menu)
      item = menu.menu_items.first

      get "/api/v1/menus/#{menu.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => menu.id,
        "name" => menu.name,
        "status" => "active"
      )
      expect(response.parsed_body.dig("data", "menu_items").first).to include(
        "id" => item.id,
        "available" => true,
        "price_override" => item.price_override.to_s,
        "effective_price" => item.price_override.to_s
      )
    end

    it "returns 404 when menu does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/menus/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/menus" do
    it "creates a menu with items for admins and registers an audit log" do
      admin = create(:user, :admin)
      product = create(:product)

      expect do
        post "/api/v1/menus",
             params: valid_menu_params(product),
             headers: authorization_header_for(admin),
             as: :json
      end.to change(Menu, :count).by(1)
        .and change(MenuItem, :count).by(1)
        .and change(AuditLog, :count).by(1)

      menu = Menu.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => menu.id,
        "name" => "Cardapio da Semana",
        "status" => "active",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "menus.create",
        auditable: menu
      )
    end

    it "creates a menu for managers" do
      manager = create(:user, :manager)
      product = create(:product)

      post "/api/v1/menus",
           params: valid_menu_params(product),
           headers: authorization_header_for(manager),
           as: :json

      expect(response).to have_http_status(:created)
    end

    it "does not allow inactive product in active menu" do
      admin = create(:user, :admin)
      product = create(:product, :inactive)

      post "/api/v1/menus",
           params: valid_menu_params(product),
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "menu_items",
          "message" => "cannot include inactive products in an active menu"
        }
      )
    end

    it "does not allow duplicated products" do
      admin = create(:user, :admin)
      product = create(:product)

      post "/api/v1/menus",
           params: {
             menu: {
               name: "Duplicado",
               start_date: Date.current.iso8601,
               end_date: (Date.current + 7.days).iso8601,
               status: "active",
               menu_items_attributes: [
                 { product_id: product.id, available: true, price_override: "21.90" },
                 { product_id: product.id, available: true, price_override: "22.90" }
               ]
             }
           },
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "menu_items",
          "message" => "cannot have duplicated products"
        }
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      product = create(:product)

      post "/api/v1/menus",
           params: valid_menu_params(product),
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/menus/:id" do
    it "updates a menu and nested items for managers and registers an audit log" do
      manager = create(:user, :manager)
      menu = create(:menu)
      old_item = menu.menu_items.first
      new_product = create(:product)

      patch "/api/v1/menus/#{menu.id}",
            params: {
              menu: {
                name: "Cardapio Atualizado",
                menu_items_attributes: [
                  { id: old_item.id, _destroy: true },
                  { product_id: new_product.id, available: true, price_override: "25.90" }
                ]
              }
            },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(menu.reload.name).to eq("Cardapio Atualizado")
      expect(menu.menu_items.pluck(:product_id)).to eq([new_product.id])
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "menus.update",
        auditable: menu
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name")
    end

    it "returns validation errors" do
      admin = create(:user, :admin)
      menu = create(:menu)

      patch "/api/v1/menus/#{menu.id}",
            params: { menu: { end_date: menu.start_date - 1.day } },
            headers: authorization_header_for(admin),
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "end_date",
          "message" => "can't be before start date"
        }
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      menu = create(:menu)

      patch "/api/v1/menus/#{menu.id}",
            params: { menu: { name: "Novo" } },
            headers: authorization_header_for(cashier),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/menus/:id" do
    it "soft deletes a menu for admins and registers an audit log" do
      admin = create(:user, :admin)
      menu = create(:menu)

      delete "/api/v1/menus/#{menu.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(menu.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "menus.destroy",
        auditable: menu
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      menu = create(:menu)

      delete "/api/v1/menus/#{menu.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(menu.reload.active).to be(true)
    end
  end

  def valid_menu_params(product)
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

    { "Authorization" => "Bearer #{token}" }
  end
end
