class CashSessionCloser
  SIGNED_MOVEMENT_TYPES = {
    "sale" => 1,
    "income" => 1,
    "expense" => -1,
    "adjustment" => 1
  }.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(cash_session:, user:, closing_amount:, notes: nil, closed_at: Time.current)
    @cash_session = cash_session
    @user = user
    @closing_amount = closing_amount
    @notes = notes
    @closed_at = closed_at || Time.current
  end

  def call
    CashSession.transaction do
      cash_session.lock!
      raise ActiveRecord::RecordInvalid, already_closed_session unless cash_session.opened?
      raise ActiveRecord::RecordInvalid, missing_closing_amount if closing_amount.blank?

      expected_amount = calculate_expected_amount
      difference_amount = BigDecimal(closing_amount.to_s) - expected_amount

      cash_session.cash_movements.create!(
        user: user,
        movement_type: :closing,
        amount: closing_amount,
        description: "Fechamento de caixa",
        occurred_at: closed_at
      )
      cash_session.update!(
        closed_by: user,
        closing_amount: closing_amount,
        expected_amount: expected_amount,
        difference_amount: difference_amount,
        closed_at: closed_at,
        status: :closed,
        notes: notes.presence || cash_session.notes
      )

      cash_session
    end
  end

  private

  attr_reader :cash_session, :user, :closing_amount, :notes, :closed_at

  def calculate_expected_amount
    movement_total = cash_session.cash_movements.where(movement_type: SIGNED_MOVEMENT_TYPES.keys).sum do |movement|
      movement.amount * SIGNED_MOVEMENT_TYPES.fetch(movement.movement_type)
    end

    cash_session.opening_amount + movement_total
  end

  def already_closed_session
    cash_session.tap do |session|
      session.errors.add(:status, "must be opened")
    end
  end

  def missing_closing_amount
    cash_session.tap do |session|
      session.errors.add(:closing_amount, "can't be blank")
    end
  end
end
