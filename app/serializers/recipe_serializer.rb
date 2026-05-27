class RecipeSerializer
  def initialize(recipe)
    @recipe = recipe
  end

  def as_json(*)
    {
      id: recipe.id,
      product: product_payload,
      name: recipe.name,
      description: recipe.description,
      active: recipe.active,
      recipe_items: recipe.recipe_items.map { |item| item_payload(item) },
      created_at: recipe.created_at&.iso8601,
      updated_at: recipe.updated_at&.iso8601
    }
  end

  private

  attr_reader :recipe

  def product_payload
    {
      id: recipe.product.id,
      code: recipe.product.code,
      name: recipe.product.name
    }
  end

  def item_payload(item)
    {
      id: item.id,
      ingredient: {
        id: item.ingredient.id,
        code: item.ingredient.code,
        name: item.ingredient.name
      },
      quantity: item.quantity.to_s,
      unit: item.unit
    }
  end
end
