class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  has_many :audit_logs, dependent: :restrict_with_exception
  has_many :opened_cash_sessions, class_name: "CashSession", foreign_key: :opened_by_id, dependent: :restrict_with_exception, inverse_of: :opened_by
  has_many :closed_cash_sessions, class_name: "CashSession", foreign_key: :closed_by_id, dependent: :restrict_with_exception, inverse_of: :closed_by
  has_many :cash_movements, dependent: :restrict_with_exception

  devise :database_authenticatable,
         :recoverable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: self

  enum :role, {
    admin: 0,
    manager: 1,
    cashier: 2
  }

  before_validation :ensure_jti

  validates :name, :cpf, :role, :jti, presence: true
  validates :cpf, :jti, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  validates :active, inclusion: { in: [true, false] }
  validate :birth_date_cannot_be_in_the_future

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end

  private

  def ensure_jti
    self.jti = SecureRandom.uuid if jti.blank?
  end

  def birth_date_cannot_be_in_the_future
    return if birth_date.blank? || birth_date <= Date.current

    errors.add(:birth_date, "can't be in the future")
  end
end
