class CreateCashMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_movements do |t|
      t.references :cash_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :movement_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :description
      t.string :source_type
      t.bigint :source_id
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :cash_movements, :movement_type
    add_index :cash_movements, :occurred_at
    add_index :cash_movements, [:source_type, :source_id]
  end
end
