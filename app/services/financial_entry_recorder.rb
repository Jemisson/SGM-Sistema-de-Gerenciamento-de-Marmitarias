class FinancialEntryRecorder
  def self.create(...)
    new(...).create
  end

  def self.update(...)
    new(...).update
  end

  def self.cancel(...)
    new(...).cancel
  end

  def initialize(user:, attributes:, financial_entry: nil)
    @user = user
    @attributes = attributes.to_h.symbolize_keys
    @financial_entry = financial_entry
  end

  def create
    FinancialEntry.transaction do
      entry = FinancialEntry.create!(entry_attributes.merge(user: user))
      create_cash_movement(entry)
      entry
    end
  end

  def update
    FinancialEntry.transaction do
      raise ActiveRecord::RecordInvalid, not_manual_entry unless financial_entry.manual?

      financial_entry.update!(entry_attributes)
      rebuild_cash_movement(financial_entry)
      financial_entry
    end
  end

  def cancel
    FinancialEntry.transaction do
      raise ActiveRecord::RecordInvalid, not_manual_entry unless financial_entry.manual?

      financial_entry.update!(active: false)
      financial_entry.cash_session&.cash_movements&.where(source: financial_entry)&.destroy_all
      financial_entry
    end
  end

  private

  attr_reader :user, :attributes, :financial_entry

  def entry_attributes
    attributes.slice(
      :cash_session_id,
      :entry_type,
      :category,
      :description,
      :amount,
      :payment_method,
      :occurred_at,
      :active
    )
  end

  def create_cash_movement(entry)
    return unless entry.cash_session

    entry.cash_session.cash_movements.create!(
      user: user,
      movement_type: entry.entry_type,
      amount: entry.amount,
      description: entry.description,
      source: entry,
      occurred_at: entry.occurred_at
    )
  end

  def rebuild_cash_movement(entry)
    entry.cash_session&.cash_movements&.where(source: entry)&.destroy_all
    create_cash_movement(entry) if entry.active?
  end

  def not_manual_entry
    financial_entry.tap do |entry|
      entry.errors.add(:base, "source entries cannot be changed manually")
    end
  end
end
