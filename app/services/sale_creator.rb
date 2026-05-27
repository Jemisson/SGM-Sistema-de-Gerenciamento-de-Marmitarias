class SaleCreator
  def self.call(...)
    new(...).call
  end

  def initialize(user:, payment_method:, items:, cash_session_id: nil, sold_at: Time.current)
    @user = user
    @payment_method = payment_method
    @items = Array(items)
    @cash_session_id = cash_session_id
    @sold_at = sold_at || Time.current
  end

  def call
    Sale.transaction do
      session = resolve_cash_session
      session.lock!
      raise ActiveRecord::RecordInvalid, invalid_sale(:cash_session, "must be opened") unless session.opened?

      sale = build_sale(session)
      raise ActiveRecord::RecordInvalid, sale if sale.errors.any? || !sale.valid?

      sale.save!
      create_cash_movement(sale)
      consume_stock!(sale)

      sale
    end
  end

  private

  attr_reader :user, :payment_method, :items, :cash_session_id, :sold_at

  def resolve_cash_session
    scope = user.manager? ? CashSession.all : user.opened_cash_sessions
    session = if cash_session_id.present?
                scope.find(cash_session_id)
              else
                user.opened_cash_sessions.opened.order(opened_at: :desc, id: :desc).first
              end

    return session if session

    raise ActiveRecord::RecordInvalid, invalid_sale(:cash_session, "must be opened")
  end

  def build_sale(cash_session)
    sale = Sale.new(
      cash_session: cash_session,
      user: user,
      payment_method: payment_method,
      status: :confirmed,
      sold_at: sold_at,
      total_amount: 0
    )

    if items.blank?
      sale.errors.add(:sale_items, "must have at least one item")
      return sale
    end

    items.each do |item|
      add_sale_item(sale, item)
    end
    sale.total_amount = sale.sale_items.sum(&:total_price)
    sale
  end

  def add_sale_item(sale, item)
    attributes = item.to_h.symbolize_keys
    product = Product.includes(recipe: { recipe_items: :ingredient }).find(attributes.fetch(:product_id))
    quantity = Integer(attributes.fetch(:quantity))

    sale.errors.add(:product, "must be active") unless product.active?
    sale.errors.add(:quantity, "must be greater than 0") unless quantity.positive?
    sale.errors.add(:product, "must have an active recipe") unless product.recipe&.active?

    return if sale.errors.any?

    unit_price = product.sale_price
    sale.sale_items.build(
      product: product,
      quantity: quantity,
      unit_price: unit_price,
      total_price: unit_price * quantity
    )
  rescue KeyError
    sale.errors.add(:sale_items, "must include product_id and quantity")
  rescue ArgumentError
    sale.errors.add(:quantity, "must be an integer")
  end

  def create_cash_movement(sale)
    sale.cash_session.cash_movements.create!(
      user: user,
      movement_type: :sale,
      amount: sale.total_amount,
      description: "Venda ##{sale.id}",
      source: sale,
      occurred_at: sale.sold_at
    )
  end

  def consume_stock!(sale)
    sale.sale_items.each do |sale_item|
      sale_item.product.recipe.recipe_items.each do |recipe_item|
        StockMovementCreator.call(
          user: user,
          ingredient: recipe_item.ingredient,
          movement_type: :sale_consumption,
          quantity: recipe_item.quantity * sale_item.quantity,
          reason: "Venda ##{sale.id}",
          source: sale,
          occurred_at: sale.sold_at
        )
      end
    end
  end

  def invalid_sale(field, message)
    Sale.new(total_amount: 0, payment_method: payment_method, sold_at: sold_at).tap do |sale|
      sale.errors.add(field, message)
    end
  end
end
