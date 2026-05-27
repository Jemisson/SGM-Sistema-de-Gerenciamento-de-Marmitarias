class Recipe < ApplicationRecord
  belongs_to :product
  has_many :recipe_items, dependent: :destroy, inverse_of: :recipe
  has_many :ingredients, through: :recipe_items

  accepts_nested_attributes_for :recipe_items, allow_destroy: true

  validates :name, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :product_id, uniqueness: { conditions: -> { where(active: true) } }, if: :active?
  validate :must_have_at_least_one_item
  validate :product_must_be_active
  validate :recipe_items_must_have_unique_ingredients

  scope :active, -> { where(active: true) }

  private

  def must_have_at_least_one_item
    return if recipe_items.reject(&:marked_for_destruction?).any?

    errors.add(:recipe_items, "must have at least one item")
  end

  def product_must_be_active
    return unless active?
    return if product.blank? || product.active?

    errors.add(:product, "must be active")
  end

  def recipe_items_must_have_unique_ingredients
    ingredient_ids = recipe_items.reject(&:marked_for_destruction?).filter_map(&:ingredient_id)
    return if ingredient_ids.uniq.size == ingredient_ids.size

    errors.add(:recipe_items, "cannot have duplicated ingredients")
  end
end
