class MenuSerializer
  def initialize(menu)
    @menu = menu
  end

  def as_json(*)
    {
      id: menu.id,
      name: menu.name,
      start_date: menu.start_date&.iso8601,
      end_date: menu.end_date&.iso8601,
      status: menu.status,
      active: menu.active,
      menu_items: menu.menu_items.map { |item| item_payload(item) },
      created_at: menu.created_at&.iso8601,
      updated_at: menu.updated_at&.iso8601
    }
  end

  private

  attr_reader :menu

  def item_payload(item)
    {
      id: item.id,
      product: {
        id: item.product.id,
        code: item.product.code,
        name: item.product.name,
        sale_price: item.product.sale_price.to_s
      },
      available: item.available,
      price_override: item.price_override&.to_s,
      effective_price: (item.price_override || item.product.sale_price).to_s
    }
  end
end
