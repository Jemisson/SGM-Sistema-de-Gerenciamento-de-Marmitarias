require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  describe "GET /api/v1/products" do
    it "lists only active products by default" do
      cashier = create(:user, :cashier)
      active_product = create(:product, name: "Marmita Fit")
      create(:product, :inactive, name: "Marmita Antiga")

      get "/api/v1/products", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_product.id])
    end

    it "filters by name, code, category and active" do
      cashier = create(:user, :cashier)
      category = create(:category)
      included_product = create(:product, :inactive, category: category, name: "Marmita Frango", code: "MFR001")
      create(:product, :inactive, category: category, name: "Marmita Carne", code: "MCA001")
      create(:product, :inactive, name: "Marmita Frango", code: "OUT001")

      get "/api/v1/products",
          params: {
            name: "Frango",
            code: "MFR001",
            category_id: category.id,
            active: false
          },
          headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_product.id])
    end

    it "requires authentication" do
      get "/api/v1/products"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/products/:id" do
    it "shows an active product for cashiers" do
      cashier = create(:user, :cashier)
      product = create(:product)

      get "/api/v1/products/#{product.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => product.id,
        "code" => product.code,
        "name" => product.name,
        "sale_price" => product.sale_price.to_s,
        "active" => true
      )
    end

    it "returns 404 when product does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/products/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/products" do
    it "creates a product for admins and registers an audit log" do
      admin = create(:user, :admin)
      category = create(:category)

      expect do
        post "/api/v1/products",
             params: {
               product: {
                 code: "M001",
                 name: "Marmita de Frango",
                 description: "Arroz, feijao e frango",
                 category_id: category.id,
                 sale_price: "24.90"
               }
             },
             headers: authorization_header_for(admin)
      end.to change(Product, :count).by(1)
        .and change(AuditLog, :count).by(1)

      product = Product.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => product.id,
        "code" => "M001",
        "name" => "Marmita de Frango",
        "sale_price" => "24.9",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "products.create",
        auditable: product
      )
    end

    it "accepts an image upload" do
      manager = create(:user, :manager)
      category = create(:category)
      image = fixture_file_upload("product.jpg", "image/jpeg")

      post "/api/v1/products",
           params: {
             product: {
               code: "MIMG001",
               name: "Marmita com Imagem",
               category_id: category.id,
               sale_price: "29.90",
               image: image
             }
           },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
      expect(Product.last.image).to be_attached
      expect(response.parsed_body.dig("data", "image_url")).to be_present
    end

    it "creates a product for managers" do
      manager = create(:user, :manager)
      category = create(:category)

      post "/api/v1/products",
           params: {
             product: {
               code: "M002",
               name: "Marmita Executiva",
               category_id: category.id,
               sale_price: "28.90"
             }
           },
           headers: authorization_header_for(manager)

      expect(response).to have_http_status(:created)
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      category = create(:category)

      post "/api/v1/products",
           params: {
             product: {
               code: "M003",
               name: "Marmita Caixa",
               category_id: category.id,
               sale_price: "19.90"
             }
           },
           headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns validation errors" do
      admin = create(:user, :admin)

      post "/api/v1/products",
           params: { product: { code: "", name: "", sale_price: "0" } },
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
          "field" => "sale_price",
          "message" => "must be greater than 0"
        }
      )
    end
  end

  describe "PATCH /api/v1/products/:id" do
    it "updates a product for managers and registers an audit log" do
      manager = create(:user, :manager)
      product = create(:product, name: "Antiga")

      patch "/api/v1/products/#{product.id}",
            params: { product: { name: "Nova" } },
            headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(product.reload.name).to eq("Nova")
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "products.update",
        auditable: product
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name")
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      product = create(:product)

      patch "/api/v1/products/#{product.id}",
            params: { product: { name: "Nova" } },
            headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/products/:id" do
    it "soft deletes a product for admins and registers an audit log" do
      admin = create(:user, :admin)
      product = create(:product)

      delete "/api/v1/products/#{product.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(product.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "products.destroy",
        auditable: product
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      product = create(:product)

      delete "/api/v1/products/#{product.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(product.reload.active).to be(true)
    end
  end

  def authorization_header_for(user)
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    user.on_jwt_dispatch(token, payload) if user.respond_to?(:on_jwt_dispatch)

    { "Authorization" => "Bearer #{token}" }
  end
end
