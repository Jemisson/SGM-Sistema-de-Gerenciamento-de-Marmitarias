require "rails_helper"

RSpec.describe "Api::V1::Ingredients", type: :request do
  describe "GET /api/v1/ingredients" do
    it "lists active ingredients by default" do
      admin = create(:user, :admin)
      active_ingredient = create(:ingredient, name: "Arroz")
      create(:ingredient, :inactive, name: "Feijao")

      get "/api/v1/ingredients", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_ingredient.id])
    end

    it "filters by name, code, category, supplier, active and below minimum stock" do
      manager = create(:user, :manager)
      category = create(:category)
      supplier = create(:supplier)
      included_ingredient = create(
        :ingredient,
        :inactive,
        :below_minimum_stock,
        code: "INS-FILTER",
        name: "Arroz Branco",
        category: category,
        supplier: supplier
      )
      create(:ingredient, :inactive, :below_minimum_stock, code: "INS-OTHER", name: "Arroz Integral")
      create(:ingredient, code: "INS-ACTIVE", name: "Arroz Branco", category: category, supplier: supplier)

      get "/api/v1/ingredients",
          params: {
            name: "Branco",
            code: "INS-FILTER",
            category_id: category.id,
            supplier_id: supplier.id,
            active: false,
            below_minimum_stock: true
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_ingredient.id])
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/ingredients", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/ingredients"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/ingredients/:id" do
    it "shows an ingredient for managers" do
      manager = create(:user, :manager)
      ingredient = create(:ingredient)

      get "/api/v1/ingredients/#{ingredient.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => ingredient.id,
        "code" => ingredient.code,
        "name" => ingredient.name,
        "unit" => ingredient.unit,
        "active" => true
      )
      expect(response.parsed_body.dig("data", "category")).to include(
        "id" => ingredient.category_id,
        "name" => ingredient.category.name
      )
      expect(response.parsed_body.dig("data", "supplier")).to include(
        "id" => ingredient.supplier_id,
        "name" => ingredient.supplier.name
      )
    end

    it "returns 404 when ingredient does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/ingredients/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/ingredients" do
    it "creates an ingredient for admins and registers an audit log" do
      admin = create(:user, :admin)
      category = create(:category)
      supplier = create(:supplier)

      expect do
        post "/api/v1/ingredients",
             params: {
               ingredient: {
                 code: "INS-CREATE",
                 name: "Arroz",
                 category_id: category.id,
                 supplier_id: supplier.id,
                 unit: "kg",
                 current_stock: "10.500",
                 minimum_stock: "2.000",
                 purchase_price: "15.90"
               }
             },
             headers: authorization_header_for(admin)
      end.to change(Ingredient, :count).by(1)
        .and change(AuditLog, :count).by(1)

      ingredient = Ingredient.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => ingredient.id,
        "code" => "INS-CREATE",
        "name" => "Arroz",
        "unit" => "kg",
        "current_stock" => "10.5",
        "minimum_stock" => "2.0",
        "purchase_price" => "15.9",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "ingredients.create",
        auditable: ingredient
      )
    end

    it "creates an ingredient for managers" do
      manager = create(:user, :manager)
      category = create(:category)
      supplier = create(:supplier)

      post "/api/v1/ingredients",
           params: {
             ingredient: {
               code: "INS-MANAGER",
               name: "Feijao",
               category_id: category.id,
               supplier_id: supplier.id,
               unit: "kg"
             }
           },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      post "/api/v1/ingredients",
           params: { ingredient: { code: "INS-CASH", name: "Oleo", unit: "un" } },
           headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)

      post "/api/v1/ingredients",
           params: { ingredient: { code: "", name: "", unit: "" } },
           headers: authorization_header_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "code",
          "message" => "can't be blank"
        },
        {
          "field" => "name",
          "message" => "can't be blank"
        },
        {
          "field" => "category",
          "message" => "must exist"
        },
        {
          "field" => "unit",
          "message" => "can't be blank"
        }
      )
    end
  end

  describe "PATCH /api/v1/ingredients/:id" do
    it "updates an ingredient and registers an audit log" do
      manager = create(:user, :manager)
      ingredient = create(:ingredient, name: "Antigo")

      patch "/api/v1/ingredients/#{ingredient.id}",
            params: { ingredient: { name: "Novo", current_stock: "3.000" } },
            headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(ingredient.reload).to have_attributes(name: "Novo", current_stock: BigDecimal("3.0"))
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "ingredients.update",
        auditable: ingredient
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name", "current_stock")
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      ingredient = create(:ingredient)

      patch "/api/v1/ingredients/#{ingredient.id}",
            params: { ingredient: { name: "Novo" } },
            headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/ingredients/:id" do
    it "soft deletes an ingredient and registers an audit log" do
      admin = create(:user, :admin)
      ingredient = create(:ingredient)

      expect do
        delete "/api/v1/ingredients/#{ingredient.id}", headers: authorization_header_for(admin)
      end.not_to change(Ingredient, :count)

      expect(response).to have_http_status(:ok)
      expect(ingredient.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "ingredients.destroy",
        auditable: ingredient
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      ingredient = create(:ingredient)

      delete "/api/v1/ingredients/#{ingredient.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(ingredient.reload.active).to be(true)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
