class Product < ApplicationRecord
  belongs_to :category
  has_one :recipe, dependent: :restrict_with_exception

  has_one_attached :image

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :sale_price, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
end
