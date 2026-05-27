require "rails_helper"

RSpec.describe "Api::V1::Recipes", type: :request do
  describe "GET /api/v1/recipes" do
    it "lists only active recipes by default for admins" do
      admin = create(:user, :admin)
      active_recipe = create(:recipe, name: "Marmita Fit")
      create(:recipe, :inactive, name: "Receita Inativa")

      get "/api/v1/recipes", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([active_recipe.id])
    end

    it "filters by name, product and active" do
      manager = create(:user, :manager)
      product = create(:product)
      included_recipe = create(:recipe, :inactive, product: product, name: "Marmita Frango")
      create(:recipe, :inactive, name: "Marmita Carne")
      create(:recipe, name: "Marmita Frango")

      get "/api/v1/recipes",
          params: {
            name: "Frango",
            product_id: product.id,
            active: false
          },
          headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data").pluck("id")).to eq([included_recipe.id])
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)

      get "/api/v1/recipes", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
    end

    it "requires authentication" do
      get "/api/v1/recipes"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/recipes/:id" do
    it "shows a recipe for managers" do
      manager = create(:user, :manager)
      recipe = create(:recipe)
      item = recipe.recipe_items.first

      get "/api/v1/recipes/#{recipe.id}", headers: authorization_header_for(manager)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => recipe.id,
        "name" => recipe.name,
        "active" => true
      )
      expect(response.parsed_body.dig("data", "product")).to include(
        "id" => recipe.product_id,
        "name" => recipe.product.name
      )
      expect(response.parsed_body.dig("data", "recipe_items").first).to include(
        "id" => item.id,
        "quantity" => item.quantity.to_s,
        "unit" => item.unit
      )
    end

    it "returns 404 when recipe does not exist" do
      admin = create(:user, :admin)

      get "/api/v1/recipes/999999", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/recipes" do
    it "creates a recipe with items for admins and registers an audit log" do
      admin = create(:user, :admin)
      product = create(:product)
      ingredient = create(:ingredient)

      expect do
        post "/api/v1/recipes",
             params: {
               recipe: {
                 product_id: product.id,
                 name: "Receita Marmita Frango",
                 description: "Composicao padrao",
                 recipe_items_attributes: [
                   {
                     ingredient_id: ingredient.id,
                     quantity: "0.250",
                     unit: "kg"
                   }
                 ]
               }
             },
             headers: authorization_header_for(admin),
             as: :json
      end.to change(Recipe, :count).by(1)
        .and change(RecipeItem, :count).by(1)
        .and change(AuditLog, :count).by(1)

      recipe = Recipe.last

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.fetch("data")).to include(
        "id" => recipe.id,
        "name" => "Receita Marmita Frango",
        "active" => true
      )
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "recipes.create",
        auditable: recipe
      )
    end

    it "creates a recipe for managers" do
      manager = create(:user, :manager)
      product = create(:product)
      ingredient = create(:ingredient)

      post "/api/v1/recipes",
           params: valid_recipe_params(product, ingredient),
           headers: authorization_header_for(manager),
           as: :json

      expect(response).to have_http_status(:created)
    end

    it "does not allow active recipe for inactive product" do
      admin = create(:user, :admin)
      product = create(:product, :inactive)
      ingredient = create(:ingredient)

      post "/api/v1/recipes",
           params: valid_recipe_params(product, ingredient),
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "product",
          "message" => "must be active"
        }
      )
    end

    it "requires at least one item" do
      admin = create(:user, :admin)
      product = create(:product)

      post "/api/v1/recipes",
           params: {
             recipe: {
               product_id: product.id,
               name: "Receita sem itens",
               recipe_items_attributes: []
             }
           },
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "recipe_items",
          "message" => "must have at least one item"
        }
      )
    end

    it "does not allow duplicated ingredients" do
      admin = create(:user, :admin)
      product = create(:product)
      ingredient = create(:ingredient)

      post "/api/v1/recipes",
           params: {
             recipe: {
               product_id: product.id,
               name: "Receita duplicada",
               recipe_items_attributes: [
                 { ingredient_id: ingredient.id, quantity: "0.250", unit: "kg" },
                 { ingredient_id: ingredient.id, quantity: "0.100", unit: "kg" }
               ]
             }
           },
           headers: authorization_header_for(admin),
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "recipe_items",
          "message" => "cannot have duplicated ingredients"
        }
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      product = create(:product)
      ingredient = create(:ingredient)

      post "/api/v1/recipes",
           params: valid_recipe_params(product, ingredient),
           headers: authorization_header_for(cashier),
           as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/recipes/:id" do
    it "updates a recipe and nested items for managers and registers an audit log" do
      manager = create(:user, :manager)
      recipe = create(:recipe)
      old_item = recipe.recipe_items.first
      new_ingredient = create(:ingredient)

      patch "/api/v1/recipes/#{recipe.id}",
            params: {
              recipe: {
                name: "Receita Atualizada",
                recipe_items_attributes: [
                  { id: old_item.id, _destroy: true },
                  { ingredient_id: new_ingredient.id, quantity: "0.500", unit: "kg" }
                ]
              }
            },
            headers: authorization_header_for(manager),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(recipe.reload.name).to eq("Receita Atualizada")
      expect(recipe.recipe_items.pluck(:ingredient_id)).to eq([new_ingredient.id])
      expect(AuditLog.last).to have_attributes(
        user: manager,
        action: "recipes.update",
        auditable: recipe
      )
      expect(AuditLog.last.metadata.fetch("changed_fields")).to include("name")
    end

    it "does not allow removing all items" do
      admin = create(:user, :admin)
      recipe = create(:recipe)
      item = recipe.recipe_items.first

      patch "/api/v1/recipes/#{recipe.id}",
            params: {
              recipe: {
                recipe_items_attributes: [
                  { id: item.id, _destroy: true }
                ]
              }
            },
            headers: authorization_header_for(admin),
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.fetch("errors")).to include(
        {
          "field" => "recipe_items",
          "message" => "must have at least one item"
        }
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      recipe = create(:recipe)

      patch "/api/v1/recipes/#{recipe.id}",
            params: { recipe: { name: "Nova" } },
            headers: authorization_header_for(cashier),
            as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/recipes/:id" do
    it "soft deletes a recipe for admins and registers an audit log" do
      admin = create(:user, :admin)
      recipe = create(:recipe)

      delete "/api/v1/recipes/#{recipe.id}", headers: authorization_header_for(admin)

      expect(response).to have_http_status(:ok)
      expect(recipe.reload.active).to be(false)
      expect(AuditLog.last).to have_attributes(
        user: admin,
        action: "recipes.destroy",
        auditable: recipe
      )
    end

    it "forbids cashiers" do
      cashier = create(:user, :cashier)
      recipe = create(:recipe)

      delete "/api/v1/recipes/#{recipe.id}", headers: authorization_header_for(cashier)

      expect(response).to have_http_status(:forbidden)
      expect(recipe.reload.active).to be(true)
    end
  end

  def valid_recipe_params(product, ingredient)
    {
      recipe: {
        product_id: product.id,
        name: "Receita Marmita",
        recipe_items_attributes: [
          {
            ingredient_id: ingredient.id,
            quantity: "0.250",
            unit: "kg"
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
