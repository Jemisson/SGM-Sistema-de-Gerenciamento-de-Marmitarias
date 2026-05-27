class CashMovement < ApplicationRecord
  belongs_to :cash_session
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  enum :movement_type, {
    opening: 0,
    sale: 1,
    income: 2,
    expense: 3,
    adjustment: 4,
    closing: 5
  }, validate: true

  validates :amount, numericality: true
  validates :occurred_at, presence: true
  validate :cash_session_must_be_opened, on: :create

  private

  def cash_session_must_be_opened
    return if cash_session.blank? || cash_session.opened?

    errors.add(:cash_session, "must be opened")
  end
end
