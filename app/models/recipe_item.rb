class RecipeItem < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit, presence: true
  validates :ingredient_id, uniqueness: { scope: :recipe_id }
end
