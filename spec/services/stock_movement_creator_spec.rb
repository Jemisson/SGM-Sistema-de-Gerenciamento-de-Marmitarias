require "rails_helper"

RSpec.describe StockMovementCreator do
  describe ".call" do
    it "creates an entry and increases ingredient stock" do
      user = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 10)

      movement = described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :entry,
        quantity: 5,
        unit_cost: 12.5,
        reason: "Compra"
      )

      expect(movement).to be_persisted
      expect(movement).to be_entry
      expect(ingredient.reload.current_stock).to eq(BigDecimal("15.0"))
    end

    it "creates an exit and decreases ingredient stock" do
      user = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 10)

      described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :exit,
        quantity: 4,
        reason: "Uso manual"
      )

      expect(ingredient.reload.current_stock).to eq(BigDecimal("6.0"))
    end

    it "sets stock to the counted quantity for adjustment" do
      user = create(:user, :admin)
      ingredient = create(:ingredient, current_stock: 10)

      described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :adjustment,
        quantity: 7,
        reason: "Contagem física"
      )

      expect(ingredient.reload.current_stock).to eq(BigDecimal("7.0"))
    end

    it "decreases stock for production and sale consumption movements" do
      user = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 10)

      described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :production_consumption,
        quantity: 3,
        reason: "Produção"
      )
      described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :sale_consumption,
        quantity: 2,
        reason: "Venda"
      )

      expect(ingredient.reload.current_stock).to eq(BigDecimal("5.0"))
    end

    it "does not allow stock to become negative and rolls back the movement" do
      user = create(:user, :manager)
      ingredient = create(:ingredient, current_stock: 2)
      movement_count = StockMovement.count

      expect do
        described_class.call(
          user: user,
          ingredient: ingredient,
          movement_type: :exit,
          quantity: 3,
          reason: "Uso manual"
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(StockMovement.count).to eq(movement_count)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("2.0"))
    end

    it "keeps source data for future automatic integrations" do
      user = create(:user, :manager)
      ingredient = create(:ingredient)

      movement = described_class.call(
        user: user,
        ingredient: ingredient,
        movement_type: :entry,
        quantity: 1,
        source_type: "Production",
        source_id: 123
      )

      expect(movement).to have_attributes(
        source_type: "Production",
        source_id: 123
      )
    end
  end
end
