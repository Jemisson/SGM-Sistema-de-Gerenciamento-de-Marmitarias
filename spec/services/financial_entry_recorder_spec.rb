require "rails_helper"

RSpec.describe FinancialEntryRecorder do
  describe ".create" do
    it "creates a financial entry without cash movement when no cash session is informed" do
      manager = create(:user, :manager)

      expect do
        described_class.create(
          user: manager,
          attributes: {
            entry_type: "income",
            amount: "100.00",
            payment_method: "pix",
            occurred_at: Time.current,
            category: "Aporte",
            description: "Entrada manual"
          }
        )
      end.to change(FinancialEntry, :count).by(1)
      expect(CashMovement.count).to eq(0)
    end

    it "creates a cash movement when cash session is informed" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session, opened_by: manager)

      entry = nil

      expect do
        entry = described_class.create(
          user: manager,
          attributes: {
            cash_session_id: cash_session.id,
            entry_type: "expense",
            amount: "30.00",
            payment_method: "cash",
            occurred_at: Time.current,
            category: "Compra",
            description: "Compra emergencial"
          }
        )
      end.to change(FinancialEntry, :count).by(1)
        .and change(CashMovement, :count).by(1)

      expect(CashMovement.last).to have_attributes(
        cash_session: cash_session,
        user: manager,
        movement_type: "expense",
        amount: BigDecimal("30.00"),
        source: entry
      )
    end
  end

  describe ".update" do
    it "updates manual entries and rebuilds cash movement" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session, opened_by: manager)
      entry = described_class.create(
        user: manager,
        attributes: {
          cash_session_id: cash_session.id,
          entry_type: "income",
          amount: "10.00",
          payment_method: "cash",
          occurred_at: Time.current,
          category: "Entrada",
          description: "Entrada inicial"
        }
      )

      described_class.update(
        user: manager,
        financial_entry: entry,
        attributes: {
          cash_session_id: cash_session.id,
          entry_type: "expense",
          amount: "15.00",
          payment_method: "cash",
          occurred_at: Time.current,
          category: "Despesa",
          description: "Despesa atualizada"
        }
      )

      expect(entry.reload).to have_attributes(
        entry_type: "expense",
        amount: BigDecimal("15.00")
      )
      expect(CashMovement.where(source: entry).count).to eq(1)
      expect(CashMovement.find_by(source: entry)).to have_attributes(
        movement_type: "expense",
        amount: BigDecimal("15.00")
      )
    end

    it "does not update source entries" do
      entry = create(:financial_entry, :from_sale)

      expect do
        described_class.update(user: create(:user, :manager), financial_entry: entry, attributes: { amount: "20.00" })
      end.to raise_error(ActiveRecord::RecordInvalid, /source entries cannot be changed manually/)
    end
  end

  describe ".cancel" do
    it "inactivates manual entries and removes linked cash movement" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session, opened_by: manager)
      entry = described_class.create(
        user: manager,
        attributes: {
          cash_session_id: cash_session.id,
          entry_type: "income",
          amount: "10.00",
          payment_method: "cash",
          occurred_at: Time.current,
          category: "Entrada",
          description: "Entrada inicial"
        }
      )

      expect do
        described_class.cancel(user: manager, financial_entry: entry, attributes: {})
      end.to change { CashMovement.where(source: entry).count }.from(1).to(0)

      expect(entry.reload.active).to be(false)
    end
  end
end
