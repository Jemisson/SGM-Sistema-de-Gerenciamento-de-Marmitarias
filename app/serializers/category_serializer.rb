class CategorySerializer
  def initialize(category)
    @category = category
  end

  def as_json(*)
    {
      id: category.id,
      name: category.name,
      description: category.description,
      active: category.active,
      created_at: category.created_at&.iso8601,
      updated_at: category.updated_at&.iso8601
    }
  end

  private

  attr_reader :category
end
