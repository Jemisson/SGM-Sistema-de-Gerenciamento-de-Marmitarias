class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :movement_type, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :unit_cost, precision: 10, scale: 2
      t.text :reason
      t.string :source_type
      t.bigint :source_id
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :occurred_at
    add_index :stock_movements, [:source_type, :source_id]
  end
end
