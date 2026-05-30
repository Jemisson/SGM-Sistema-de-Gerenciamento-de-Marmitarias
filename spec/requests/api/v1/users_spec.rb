require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    it "lists only active users by default with pagination" do
      admin = create(:user, :admin)
      cashier = create(:user, :cashier, name: "Caixa SGM")
      create(:user, :manager, :inactive, name: "Gerente Inativo")

      get "/api/v1/users", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to contain_exactly(admin.id, cashier.id)
      expect(response.parsed_body.fetch("meta")).to include(
        "page" => 1,
        "per_page" => 20,
        "total_count" => 2,
        "total_pages" => 1
      )
    end

    it "filters by role, name, email and active" do
      admin = create(:user, :admin)
      included_user = create(:user, :cashier, :inactive, name: "Caixa Balcao", email: "balcao@sgm.test")
      create(:user, :cashier, :inactive, name: "Caixa Delivery", email: "delivery@sgm.test")
      create(:user, :manager, :inactive, name: "Caixa Balcao", email: "gerente@sgm.test")

      get "/api/v1/users",
          params: {
            role: "cashier",
            name: "Balcao",
            email: "balcao",
            active: false
          },
          headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_user.id])
    end

    it "forbids non-admin users" do
      manager = create(:user, :manager)

      get "/api/v1/users", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/users/:id" do
    it "shows a user for admins" do
      admin = create(:user, :admin)
      cashier = create(:user, :cashier)

      get "/api/v1/users/#{cashier.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => cashier.id,
        "email" => cashier.email,
        "role" => "cashier"
      )
    end
  end

  describe "POST /api/v1/users" do
    it "creates a user for admins and registers an audit log" do
      admin = create(:user, :admin)

      expect do
        post "/api/v1/users",
             params: {
               user: {
                 name: "Novo Caixa",
                 cpf: "12312312312",
                 role: "cashier",
                 email: "novo.caixa@sgm.test",
                 password: "password123",
                 password_confirmation: "password123"
               }
             },
             headers: authorization_header_for(admin)
      end.to change(User, :count).by(1)
        .and change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "name" => "Novo Caixa",
        "email" => "novo.caixa@sgm.test",
        "role" => "cashier",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "users.create",
        auditable: User.last
      )
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "updates a user without requiring password" do
      admin = create(:user, :admin)
      cashier = create(:user, :cashier, name: "Antigo")

      patch "/api/v1/users/#{cashier.id}",
            params: { user: { name: "Novo", password: "" } },
            headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(cashier.reload.name).to eq("Novo")
    end
  end

  describe "DELETE /api/v1/users/:id" do
    it "deactivates a user" do
      admin = create(:user, :admin)
      cashier = create(:user, :cashier)

      delete "/api/v1/users/#{cashier.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(cashier.reload.active).to be(false)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
