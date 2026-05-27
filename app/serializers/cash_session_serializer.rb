class CashSessionSerializer
  def initialize(cash_session)
    @cash_session = cash_session
  end

  def as_json(*)
    {
      id: cash_session.id,
      opened_by: user_payload(cash_session.opened_by),
      closed_by: user_payload(cash_session.closed_by),
      opening_amount: cash_session.opening_amount.to_s,
      closing_amount: cash_session.closing_amount&.to_s,
      expected_amount: cash_session.expected_amount&.to_s,
      difference_amount: cash_session.difference_amount&.to_s,
      opened_at: cash_session.opened_at&.iso8601,
      closed_at: cash_session.closed_at&.iso8601,
      status: cash_session.status,
      notes: cash_session.notes,
      cash_movements: cash_session.cash_movements.map { |movement| movement_payload(movement) },
      created_at: cash_session.created_at&.iso8601,
      updated_at: cash_session.updated_at&.iso8601
    }
  end

  private

  attr_reader :cash_session

  def user_payload(user)
    return unless user

    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    }
  end

  def movement_payload(movement)
    {
      id: movement.id,
      user: user_payload(movement.user),
      movement_type: movement.movement_type,
      amount: movement.amount.to_s,
      description: movement.description,
      source_type: movement.source_type,
      source_id: movement.source_id,
      occurred_at: movement.occurred_at&.iso8601
    }
  end
end
