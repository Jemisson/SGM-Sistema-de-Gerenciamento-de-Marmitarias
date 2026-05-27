require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  describe "GET /api/v1/categories" do
    it "lists only active categories by default" do
      cashier = create(:user, :cashier)
      active_category = create(:category, name: "Bebidas")
      create(:category, :inactive, name: "Inativa")

      get "/api/v1/categories", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_category.id])
    end

    it "requires authentication" do
      get "/api/v1/categories"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/categories/:id" do
    it "shows a category for cashiers" do
      cashier = create(:user, :cashier)
      category = create(:category)

      get "/api/v1/categories/#{category.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => category.id,
        "name" => category.name,
        "active" => true
      )
    end

    it "returns 404 when category does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/categories/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/categories" do
    it "creates a category for admins and registers an audit log" do
      admin = create(:user, :admin)

      expect do
        post "/api/v1/categories",
             params: { category: { name: "Marmitas", description: "Linha principal" } },
             headers: authorization_header_for(admin)
      end.to change(Category, :count).by(1)
        .and change(AuditLog, :count).by(1)

      category = Category.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => category.id,
        "name" => "Marmitas",
        "description" => "Linha principal",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "categories.create",
        auditable: category
      )
    end

    it "creates a category for managers" do
      manager = create(:user, :manager)

      post "/api/v1/categories",
           params: { category: { name: "Bebidas" } },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      post "/api/v1/categories",
           params: { category: { name: "Sobremesas" } },
           headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)

      post "/api/v1/categories",
           params: { category: { name: "" } },
           headers: authorization_header_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq(
        "errors" => [
          {
            "field" => "name",
            "message" => "can't be blank"
          }
        ]
      )
    end
  end

  describe "PATCH /api/v1/categories/:id" do
    it "updates a category for managers and registers an audit log" do
      manager = create(:user, :manager)
      category = create(:category, name: "Antigo")

      patch "/api/v1/categories/#{category.id}",
            params: { category: { name: "Novo" } },
            headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(category.reload.name).to eq("Novo")
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "categories.update",
        auditable: category
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name")
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      category = create(:category)

      patch "/api/v1/categories/#{category.id}",
            params: { category: { name: "Novo" } },
            headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/categories/:id" do
    it "soft deletes a category for admins and registers an audit log" do
      admin = create(:user, :admin)
      category = create(:category)

      delete "/api/v1/categories/#{category.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(category.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "categories.destroy",
        auditable: category
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      category = create(:category)

      delete "/api/v1/categories/#{category.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(category.reload.active).to be(true)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
