class IngredientSerializer
  def initialize(ingredient)
    @ingredient = ingredient
  end

  def as_json(*)
    {
      id: ingredient.id,
      code: ingredient.code,
      name: ingredient.name,
      category: serialized_category,
      supplier: serialized_supplier,
      unit: ingredient.unit,
      current_stock: decimal_to_s(ingredient.current_stock),
      minimum_stock: decimal_to_s(ingredient.minimum_stock),
      purchase_price: decimal_to_s(ingredient.purchase_price),
      manufacturing_date: ingredient.manufacturing_date&.iso8601,
      expiration_date: ingredient.expiration_date&.iso8601,
      received_at: ingredient.received_at&.iso8601,
      notes: ingredient.notes,
      active: ingredient.active,
      created_at: ingredient.created_at&.iso8601,
      updated_at: ingredient.updated_at&.iso8601
    }
  end

  private

  attr_reader :ingredient

  def serialized_category
    {
      id: ingredient.category_id,
      name: ingredient.category&.name
    }
  end

  def serialized_supplier
    {
      id: ingredient.supplier_id,
      name: ingredient.supplier&.name
    }
  end

  def decimal_to_s(value)
    value&.to_s
  end
end
