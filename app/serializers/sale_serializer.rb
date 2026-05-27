class SaleSerializer
  def initialize(sale)
    @sale = sale
  end

  def as_json(*)
    {
      id: sale.id,
      cash_session_id: sale.cash_session_id,
      user: user_payload,
      total_amount: sale.total_amount.to_s,
      payment_method: sale.payment_method,
      status: sale.status,
      sold_at: sale.sold_at&.iso8601,
      sale_items: sale.sale_items.map { |item| item_payload(item) },
      created_at: sale.created_at&.iso8601,
      updated_at: sale.updated_at&.iso8601
    }
  end

  private

  attr_reader :sale

  def user_payload
    {
      id: sale.user.id,
      name: sale.user.name,
      email: sale.user.email,
      role: sale.user.role
    }
  end

  def item_payload(item)
    {
      id: item.id,
      product: {
        id: item.product.id,
        code: item.product.code,
        name: item.product.name
      },
      quantity: item.quantity,
      unit_price: item.unit_price.to_s,
      total_price: item.total_price.to_s
    }
  end
end
