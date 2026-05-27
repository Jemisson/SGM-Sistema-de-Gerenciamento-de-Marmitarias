class Supplier < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\z/

  before_destroy :prevent_physical_destroy

  validates :name, :cnpj, presence: true
  validates :cnpj, uniqueness: true
  validates :email, format: { with: EMAIL_FORMAT }, allow_blank: true
  validates :active, inclusion: { in: [true, false] }
  validates :state, length: { maximum: 2 }, allow_blank: true

  scope :active, -> { where(active: true) }

  private

  def prevent_physical_destroy
    errors.add(:base, "physical deletion is not allowed")

    throw :abort
  end
end
