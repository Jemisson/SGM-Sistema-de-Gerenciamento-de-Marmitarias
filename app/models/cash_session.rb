class CashSession < ApplicationRecord
  belongs_to :opened_by, class_name: "User", inverse_of: :opened_cash_sessions
  belongs_to :closed_by, class_name: "User", inverse_of: :closed_cash_sessions, optional: true
  has_many :cash_movements, dependent: :restrict_with_exception

  enum :status, {
    opened: 0,
    closed: 1
  }, validate: true

  validates :opening_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :closing_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :expected_amount, :difference_amount, numericality: true, allow_nil: true
  validates :opened_at, presence: true
  validates :closing_amount, :closed_at, :closed_by, presence: true, if: :closed?
  validate :closed_at_cannot_be_before_opened_at

  scope :currently_opened, -> { opened }

  private

  def closed_at_cannot_be_before_opened_at
    return if opened_at.blank? || closed_at.blank? || closed_at >= opened_at

    errors.add(:closed_at, "can't be before opened at")
  end
end
