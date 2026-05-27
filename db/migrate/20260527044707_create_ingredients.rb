class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.string :unit, null: false
      t.decimal :current_stock, precision: 12, scale: 3, null: false, default: 0
      t.decimal :minimum_stock, precision: 12, scale: 3, null: false, default: 0
      t.decimal :purchase_price, precision: 10, scale: 2
      t.date :manufacturing_date
      t.date :expiration_date
      t.date :received_at
      t.text :notes
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :ingredients, :code, unique: true
    add_index :ingredients, :name
    add_index :ingredients, :active
    add_index :ingredients, [:category_id, :active]
    add_index :ingredients, [:supplier_id, :active]
  end
end
