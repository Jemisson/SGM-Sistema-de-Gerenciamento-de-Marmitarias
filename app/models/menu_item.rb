class MenuItem < ApplicationRecord
  belongs_to :menu
  belongs_to :product

  validates :available, inclusion: { in: [true, false] }
  validates :product_id, uniqueness: { scope: :menu_id }
  validates :price_override, numericality: { greater_than: 0 }, allow_nil: true
end
