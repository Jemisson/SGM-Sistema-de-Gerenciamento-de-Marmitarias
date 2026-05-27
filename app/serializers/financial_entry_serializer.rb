class FinancialEntrySerializer
  def initialize(financial_entry)
    @financial_entry = financial_entry
  end

  def as_json(*)
    {
      id: financial_entry.id,
      cash_session_id: financial_entry.cash_session_id,
      user: user_payload,
      entry_type: financial_entry.entry_type,
      category: financial_entry.category,
      description: financial_entry.description,
      amount: financial_entry.amount.to_s,
      payment_method: financial_entry.payment_method,
      source_type: financial_entry.source_type,
      source_id: financial_entry.source_id,
      occurred_at: financial_entry.occurred_at&.iso8601,
      active: financial_entry.active,
      created_at: financial_entry.created_at&.iso8601,
      updated_at: financial_entry.updated_at&.iso8601
    }
  end

  private

  attr_reader :financial_entry

  def user_payload
    {
      id: financial_entry.user.id,
      name: financial_entry.user.name,
      email: financial_entry.user.email,
      role: financial_entry.user.role
    }
  end
end
