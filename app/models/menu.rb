class Menu < ApplicationRecord
  has_many :menu_items, dependent: :destroy, inverse_of: :menu
  has_many :products, through: :menu_items

  accepts_nested_attributes_for :menu_items, allow_destroy: true

  enum :status, {
    draft: 0,
    active: 1,
    inactive: 2
  }, validate: true

  validates :name, :start_date, :end_date, presence: true
  validates :active, inclusion: { in: [true, false] }
  validate :end_date_cannot_be_before_start_date
  validate :active_menu_items_must_have_active_products
  validate :menu_items_must_have_unique_products

  scope :enabled, -> { where(active: true) }
  scope :currently_active, lambda { |date = Date.current|
    enabled.active.where("start_date <= ? AND end_date >= ?", date, date)
  }

  private

  def end_date_cannot_be_before_start_date
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, "can't be before start date")
  end

  def active_menu_items_must_have_active_products
    return unless active?

    inactive_product = menu_items.reject(&:marked_for_destruction?).find do |item|
      item.product.present? && !item.product.active?
    end
    return unless inactive_product

    errors.add(:menu_items, "cannot include inactive products in an active menu")
  end

  def menu_items_must_have_unique_products
    product_ids = menu_items.reject(&:marked_for_destruction?).filter_map(&:product_id)
    return if product_ids.uniq.size == product_ids.size

    errors.add(:menu_items, "cannot have duplicated products")
  end
end
