module AnalyticsTestData
  def create_recipe_for(product, ingredient, quantity: 1)
    recipe = build(:recipe, product: product, items_count: 0)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient, quantity: quantity)
    recipe.save!
    recipe
  end

  def create_sale_with_item(product:, quantity:, total_amount:, sold_at:, status: :confirmed)
    sale = build(:sale, items_count: 0, total_amount: total_amount, sold_at: sold_at, status: status)
    sale.sale_items << build(
      :sale_item,
      sale: sale,
      product: product,
      quantity: quantity,
      unit_price: total_amount / quantity,
      total_price: total_amount
    )
    sale.save!
    sale
  end
end
