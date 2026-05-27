class StockMovement < ApplicationRecord
  belongs_to :ingredient
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  enum :movement_type, {
    entry: 0,
    exit: 1,
    adjustment: 2,
    production_consumption: 3,
    sale_consumption: 4
  }, validate: true

  validates :movement_type, :occurred_at, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :reason, presence: true, if: :adjustment?
end
