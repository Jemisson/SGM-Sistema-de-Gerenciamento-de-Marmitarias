class StockMovementSerializer
  def initialize(stock_movement)
    @stock_movement = stock_movement
  end

  def as_json(*)
    {
      id: stock_movement.id,
      ingredient: serialized_ingredient,
      user: serialized_user,
      movement_type: stock_movement.movement_type,
      quantity: decimal_to_s(stock_movement.quantity),
      unit_cost: decimal_to_s(stock_movement.unit_cost),
      reason: stock_movement.reason,
      source_type: stock_movement.source_type,
      source_id: stock_movement.source_id,
      occurred_at: stock_movement.occurred_at&.iso8601,
      created_at: stock_movement.created_at&.iso8601,
      updated_at: stock_movement.updated_at&.iso8601
    }
  end

  private

  attr_reader :stock_movement

  def serialized_ingredient
    {
      id: stock_movement.ingredient_id,
      code: stock_movement.ingredient&.code,
      name: stock_movement.ingredient&.name
    }
  end

  def serialized_user
    {
      id: stock_movement.user_id,
      name: stock_movement.user&.name,
      email: stock_movement.user&.email,
      role: stock_movement.user&.role
    }
  end

  def decimal_to_s(value)
    value&.to_s
  end
end
