class CashSessionOpener
  def self.call(...)
    new(...).call
  end

  def initialize(user:, opening_amount:, notes: nil, opened_at: Time.current)
    @user = user
    @opening_amount = opening_amount
    @notes = notes
    @opened_at = opened_at || Time.current
  end

  def call
    CashSession.transaction do
      raise ActiveRecord::RecordInvalid, already_opened_session if user.opened_cash_sessions.opened.exists?

      session = CashSession.create!(
        opened_by: user,
        opening_amount: opening_amount,
        opened_at: opened_at,
        status: :opened,
        notes: notes
      )
      session.cash_movements.create!(
        user: user,
        movement_type: :opening,
        amount: opening_amount,
        description: "Abertura de caixa",
        occurred_at: opened_at
      )

      session
    end
  end

  private

  attr_reader :user, :opening_amount, :notes, :opened_at

  def already_opened_session
    CashSession.new(opened_by: user, opening_amount: opening_amount, opened_at: opened_at).tap do |session|
      session.errors.add(:base, "user already has an opened cash session")
    end
  end
end
