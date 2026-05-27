class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :cash_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.integer :payment_method, null: false
      t.integer :status, null: false, default: 0
      t.datetime :sold_at, null: false

      t.timestamps
    end

    add_index :sales, :payment_method
    add_index :sales, :status
    add_index :sales, :sold_at
  end
end
