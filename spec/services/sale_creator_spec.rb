require "rails_helper"

RSpec.describe SaleCreator do
  describe ".call" do
    it "creates a sale, cash movement and stock movements transactionally" do
      cashier = create(:user, :cashier)
      cash_session = create(:cash_session, opened_by: cashier)
      product = create(:product, sale_price: 25.50)
      ingredient = create(:ingredient, current_stock: 10)
      create_recipe_for(product, ingredient, quantity: 0.500)

      expect do
        described_class.call(
          user: cashier,
          payment_method: "pix",
          items: [{ product_id: product.id, quantity: 2 }]
        )
      end.to change(Sale, :count).by(1)
        .and change(SaleItem, :count).by(1)
        .and change(CashMovement, :count).by(1)
        .and change(StockMovement, :count).by(1)

      sale = Sale.last

      expect(sale).to have_attributes(
        cash_session: cash_session,
        user: cashier,
        payment_method: "pix",
        status: "confirmed",
        total_amount: BigDecimal("51.00")
      )
      expect(sale.sale_items.last).to have_attributes(
        product: product,
        quantity: 2,
        unit_price: BigDecimal("25.50"),
        total_price: BigDecimal("51.00")
      )
      expect(CashMovement.last).to have_attributes(
        cash_session: cash_session,
        user: cashier,
        movement_type: "sale",
        amount: BigDecimal("51.00"),
        source: sale
      )
      expect(StockMovement.last).to have_attributes(
        ingredient: ingredient,
        movement_type: "sale_consumption",
        quantity: BigDecimal("1.000"),
        source: sale
      )
      expect(ingredient.reload.current_stock).to eq(BigDecimal("9.000"))
    end

    it "uses an informed opened cash session for managers" do
      manager = create(:user, :manager)
      cash_session = create(:cash_session)
      product = create(:product)
      ingredient = create(:ingredient, current_stock: 5)
      create_recipe_for(product, ingredient)

      sale = described_class.call(
        user: manager,
        cash_session_id: cash_session.id,
        payment_method: "cash",
        items: [{ product_id: product.id, quantity: 1 }]
      )

      expect(sale.cash_session).to eq(cash_session)
    end

    it "does not trust totals sent by callers" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product, sale_price: 30)
      ingredient = create(:ingredient, current_stock: 5)
      create_recipe_for(product, ingredient)

      sale = described_class.call(
        user: cashier,
        payment_method: "cash",
        items: [{ product_id: product.id, quantity: 2, total_price: "1.00", unit_price: "1.00" }]
      )

      expect(sale.total_amount).to eq(BigDecimal("60.00"))
      expect(sale.sale_items.last.unit_price).to eq(BigDecimal("30.00"))
      expect(sale.sale_items.last.total_price).to eq(BigDecimal("60.00"))
    end

    it "requires an opened cash session" do
      cashier = create(:user, :cashier)
      product = create(:product)

      expect do
        described_class.call(user: cashier, payment_method: "cash", items: [{ product_id: product.id, quantity: 1 }])
      end.to raise_error(ActiveRecord::RecordInvalid, /Cash session must be opened/)
    end

    it "requires at least one item" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)

      expect do
        described_class.call(user: cashier, payment_method: "cash", items: [])
      end.to raise_error(ActiveRecord::RecordInvalid, /Sale items must have at least one item/)
    end

    it "requires products to be active" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product, :inactive)

      expect do
        described_class.call(user: cashier, payment_method: "cash", items: [{ product_id: product.id, quantity: 1 }])
      end.to raise_error(ActiveRecord::RecordInvalid, /Product must be active/)
    end

    it "requires an active recipe for every product" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product)

      expect do
        described_class.call(user: cashier, payment_method: "cash", items: [{ product_id: product.id, quantity: 1 }])
      end.to raise_error(ActiveRecord::RecordInvalid, /Product must have an active recipe/)
    end

    it "rolls back when stock is insufficient" do
      cashier = create(:user, :cashier)
      create(:cash_session, opened_by: cashier)
      product = create(:product)
      ingredient = create(:ingredient, current_stock: 0.500)
      create_recipe_for(product, ingredient, quantity: 1.000)

      expect do
        described_class.call(user: cashier, payment_method: "cash", items: [{ product_id: product.id, quantity: 1 }])
      end.to raise_error(ActiveRecord::RecordInvalid, /Quantity would make stock negative/)

      expect(Sale.count).to eq(0)
      expect(SaleItem.count).to eq(0)
      expect(CashMovement.sale.count).to eq(0)
      expect(StockMovement.count).to eq(0)
      expect(ingredient.reload.current_stock).to eq(BigDecimal("0.500"))
    end
  end

  def create_recipe_for(product, ingredient, quantity: 0.250)
    recipe = build(:recipe, product: product, items_count: 0)
    recipe.recipe_items << build(:recipe_item, recipe: recipe, ingredient: ingredient, quantity: quantity)
    recipe.save!
    recipe
  end
end
