class ProductSerializer
  def initialize(product)
    @product = product
  end

  def as_json(*)
    {
      id: product.id,
      code: product.code,
      name: product.name,
      description: product.description,
      category: category_payload,
      sale_price: product.sale_price.to_s,
      active: product.active,
      image_url: image_url,
      created_at: product.created_at&.iso8601,
      updated_at: product.updated_at&.iso8601
    }
  end

  private

  attr_reader :product

  def category_payload
    return unless product.category

    {
      id: product.category.id,
      name: product.category.name
    }
  end

  def image_url
    return unless product.image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(product.image, only_path: true)
  end
end
