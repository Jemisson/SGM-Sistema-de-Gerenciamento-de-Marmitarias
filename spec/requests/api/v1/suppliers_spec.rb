require "rails_helper"

RSpec.describe "Api::V1::Suppliers", type: :request do
  describe "GET /api/v1/suppliers" do
    it "lists active suppliers by default" do
      admin = create(:user, :admin)
      active_supplier = create(:supplier, name: "Ativo")
      create(:supplier, :inactive, name: "Inativo")

      get "/api/v1/suppliers", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_supplier.id])
    end

    it "filters by name, cnpj and active" do
      manager = create(:user, :manager)
      included_supplier = create(:supplier, :inactive, name: "Fornecedor Norte", cnpj: "11222333000144")
      create(:supplier, :inactive, name: "Fornecedor Sul", cnpj: "55666777000188")
      create(:supplier, name: "Fornecedor Norte", cnpj: "99888777000166")

      get "/api/v1/suppliers",
          params: {
            name: "Norte",
            cnpj: "11222333000144",
            active: false
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_supplier.id])
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/suppliers", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/suppliers"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/suppliers/:id" do
    it "shows a supplier for managers" do
      manager = create(:user, :manager)
      supplier = create(:supplier)

      get "/api/v1/suppliers/#{supplier.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => supplier.id,
        "name" => supplier.name,
        "cnpj" => supplier.cnpj,
        "active" => true
      )
    end

    it "returns 404 when supplier does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/suppliers/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/suppliers" do
    it "creates a supplier for admins and registers an audit log" do
      admin = create(:user, :admin)

      expect do
        post "/api/v1/suppliers",
             params: {
               supplier: {
                 name: "Fornecedor Central",
                 cnpj: "12345678000199",
                 email: "central@sgm.test",
                 state: "PR"
               }
             },
             headers: authorization_header_for(admin)
      end.to change(Supplier, :count).by(1)
        .and change(AuditLog, :count).by(1)

      supplier = Supplier.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => supplier.id,
        "name" => "Fornecedor Central",
        "cnpj" => "12345678000199",
        "email" => "central@sgm.test",
        "state" => "PR",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "suppliers.create",
        auditable: supplier
      )
    end

    it "creates a supplier for managers" do
      manager = create(:user, :manager)

      post "/api/v1/suppliers",
           params: { supplier: { name: "Fornecedor Manager", cnpj: "11111111000111" } },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      post "/api/v1/suppliers",
           params: { supplier: { name: "Fornecedor Caixa", cnpj: "22222222000122" } },
           headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)

      post "/api/v1/suppliers",
           params: { supplier: { name: "", cnpj: "" } },
           headers: authorization_header_for(admin)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "name",
          "message" => "can't be blank"
        },
        {
          "field" => "cnpj",
          "message" => "can't be blank"
        }
      )
    end
  end

  describe "PATCH /api/v1/suppliers/:id" do
    it "updates a supplier and registers an audit log" do
      manager = create(:user, :manager)
      supplier = create(:supplier, name: "Antigo")

      patch "/api/v1/suppliers/#{supplier.id}",
            params: { supplier: { name: "Novo", state: "MS" } },
            headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(supplier.reload).to have_attributes(name: "Novo", state: "MS")
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "suppliers.update",
        auditable: supplier
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name", "state")
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      supplier = create(:supplier)

      patch "/api/v1/suppliers/#{supplier.id}",
            params: { supplier: { name: "Novo" } },
            headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/suppliers/:id" do
    it "soft deletes a supplier and registers an audit log" do
      admin = create(:user, :admin)
      supplier = create(:supplier)

      expect do
        delete "/api/v1/suppliers/#{supplier.id}", headers: authorization_header_for(admin)
      end.not_to change(Supplier, :count)

      expect(response).to have_http_status(:ok)
      expect(supplier.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "suppliers.destroy",
        auditable: supplier
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      supplier = create(:supplier)

      delete "/api/v1/suppliers/#{supplier.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(supplier.reload.active).to be(true)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
