class Sale < ApplicationRecord
  belongs_to :cash_session
  belongs_to :user
  has_many :sale_items, dependent: :restrict_with_exception

  enum :payment_method, {
    cash: 0,
    credit_card: 1,
    debit_card: 2,
    pix: 3
  }, validate: true

  enum :status, {
    confirmed: 0,
    canceled: 1
  }, validate: true

  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :sold_at, presence: true
  validate :must_have_at_least_one_item

  private

  def must_have_at_least_one_item
    return if sale_items.any?

    errors.add(:sale_items, "must have at least one item")
  end
end
