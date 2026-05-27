require "rails_helper"

RSpec.describe CashSessionOpener do
  describe ".call" do
    it "opens a cash session and creates an opening movement" do
      user = create(:user, :cashier)

      expect do
        described_class.call(user: user, opening_amount: "100.00", notes: "Inicio")
      end.to change(CashSession, :count).by(1)
        .and change(CashMovement, :count).by(1)

      session = CashSession.last

      expect(session).to have_attributes(
        opened_by: user,
        status: "opened",
        opening_amount: BigDecimal("100.00"),
        notes: "Inicio"
      )
      expect(session.cash_movements.last).to have_attributes(
        user: user,
        movement_type: "opening",
        amount: BigDecimal("100.00")
      )
    end

    it "does not allow the same user to open another cash session" do
      user = create(:user, :cashier)
      create(:cash_session, opened_by: user)

      expect do
        described_class.call(user: user, opening_amount: "50.00")
      end.to raise_error(ActiveRecord::RecordInvalid, /user already has an opened cash session/)
      expect(CashSession.count).to eq(1)
    end
  end
end
