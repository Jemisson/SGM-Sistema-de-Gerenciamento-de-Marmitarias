require "rails_helper"

RSpec.describe CashSessionCloser do
  describe ".call" do
    it "closes a cash session and calculates expected and difference amounts" do
      user = create(:user, :manager)
      session = create(:cash_session, opening_amount: 100)
      create(:cash_movement, cash_session: session, movement_type: :sale, amount: 30)
      create(:cash_movement, cash_session: session, movement_type: :income, amount: 10)
      create(:cash_movement, cash_session: session, movement_type: :expense, amount: 15)
      create(:cash_movement, cash_session: session, movement_type: :adjustment, amount: -5)

      described_class.call(cash_session: session, user: user, closing_amount: "125.00", closed_at: session.opened_at + 8.hours)

      expect(session.reload).to have_attributes(
        closed_by: user,
        status: "closed",
        closing_amount: BigDecimal("125.00"),
        expected_amount: BigDecimal("120.00"),
        difference_amount: BigDecimal("5.00")
      )
      expect(session.cash_movements.last).to have_attributes(
        movement_type: "closing",
        amount: BigDecimal("125.00")
      )
    end

    it "requires closing amount" do
      session = create(:cash_session)

      expect do
        described_class.call(cash_session: session, user: create(:user, :manager), closing_amount: nil)
      end.to raise_error(ActiveRecord::RecordInvalid, /Closing amount can't be blank/)
    end

    it "does not close an already closed session" do
      session = create(:cash_session, :closed)

      expect do
        described_class.call(cash_session: session, user: create(:user, :manager), closing_amount: "100.00")
      end.to raise_error(ActiveRecord::RecordInvalid, /Status must be opened/)
    end
  end
end
