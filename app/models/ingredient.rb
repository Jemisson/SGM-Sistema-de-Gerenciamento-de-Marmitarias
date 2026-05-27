class Ingredient < ApplicationRecord
  belongs_to :category
  belongs_to :supplier

  validates :code, presence: true, uniqueness: true
  validates :name, :unit, presence: true
  validates :current_stock, :minimum_stock, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :active, inclusion: { in: [true, false] }
  validate :manufacturing_date_cannot_be_after_expiration_date
  validate :received_at_cannot_be_before_manufacturing_date

  scope :active, -> { where(active: true) }
  scope :below_minimum_stock, -> { where("current_stock < minimum_stock") }

  private

  def manufacturing_date_cannot_be_after_expiration_date
    return if manufacturing_date.blank? || expiration_date.blank? || manufacturing_date <= expiration_date

    errors.add(:manufacturing_date, "can't be after expiration date")
  end

  def received_at_cannot_be_before_manufacturing_date
    return if received_at.blank? || manufacturing_date.blank? || received_at >= manufacturing_date

    errors.add(:received_at, "can't be before manufacturing date")
  end
end
