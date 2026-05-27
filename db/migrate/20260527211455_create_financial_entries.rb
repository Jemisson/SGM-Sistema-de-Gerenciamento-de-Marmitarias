class CreateFinancialEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_entries do |t|
      t.references :cash_session, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.string :category
      t.text :description
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :payment_method, null: false
      t.string :source_type
      t.bigint :source_id
      t.datetime :occurred_at, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :financial_entries, :entry_type
    add_index :financial_entries, :payment_method
    add_index :financial_entries, :category
    add_index :financial_entries, :occurred_at
    add_index :financial_entries, :active
    add_index :financial_entries, [:source_type, :source_id]
  end
end
