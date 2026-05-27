class StockMovementCreator
  CONSUMPTION_TYPES = %w[exit production_consumption sale_consumption].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(user:, ingredient:, movement_type:, quantity:, unit_cost: nil, reason: nil, source: nil, source_type: nil, source_id: nil, occurred_at: Time.current)
    @user = user
    @ingredient = ingredient
    @movement_type = movement_type
    @quantity = quantity
    @unit_cost = unit_cost.presence
    @reason = reason
    @source = source
    @source_type = source_type
    @source_id = source_id
    @occurred_at = occurred_at || Time.current
  end

  def call
    StockMovement.transaction do
      movement = build_movement
      movement.validate!

      ingredient.lock!
      new_stock = calculate_new_stock(movement)
      raise ActiveRecord::RecordInvalid, invalid_stock_movement(movement) if new_stock.negative?

      movement.save!
      ingredient.update!(current_stock: new_stock)

      movement
    end
  end

  private

  attr_reader :user, :ingredient, :movement_type, :quantity, :unit_cost, :reason, :source, :source_type, :source_id, :occurred_at

  def build_movement
    StockMovement.new(
      user: user,
      ingredient: ingredient,
      movement_type: movement_type,
      quantity: quantity,
      unit_cost: unit_cost,
      reason: reason,
      source: source,
      source_type: source_type,
      source_id: source_id,
      occurred_at: occurred_at
    )
  end

  def calculate_new_stock(movement)
    case movement.movement_type
    when "entry"
      ingredient.current_stock + movement.quantity
    when "adjustment"
      movement.quantity
    when *CONSUMPTION_TYPES
      ingredient.current_stock - movement.quantity
    else
      movement.quantity
    end
  end

  def invalid_stock_movement(movement)
    movement.tap do |movement|
      movement.errors.add(:quantity, "would make stock negative")
    end
  end
end
