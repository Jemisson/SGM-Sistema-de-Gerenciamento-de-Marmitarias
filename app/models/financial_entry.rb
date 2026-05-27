class FinancialEntry < ApplicationRecord
  belongs_to :cash_session, optional: true
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  enum :entry_type, {
    income: 0,
    expense: 1
  }, validate: true

  enum :payment_method, {
    cash: 0,
    credit_card: 1,
    debit_card: 2,
    pix: 3,
    bank_transfer: 4,
    other: 5
  }, validate: true

  validates :amount, numericality: { greater_than: 0 }
  validates :occurred_at, presence: true
  validates :description, presence: true, if: :expense?
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
  scope :manual, -> { where(source_type: nil, source_id: nil) }

  def manual?
    source_type.blank? && source_id.blank?
  end
end
