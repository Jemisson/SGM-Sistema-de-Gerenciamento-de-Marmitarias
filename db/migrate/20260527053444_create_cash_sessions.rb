class CreateCashSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_sessions do |t|
      t.references :opened_by, null: false, foreign_key: { to_table: :users }
      t.references :closed_by, null: true, foreign_key: { to_table: :users }
      t.decimal :opening_amount, precision: 10, scale: 2, null: false
      t.decimal :closing_amount, precision: 10, scale: 2
      t.decimal :expected_amount, precision: 10, scale: 2
      t.decimal :difference_amount, precision: 10, scale: 2
      t.datetime :opened_at, null: false
      t.datetime :closed_at
      t.integer :status, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :cash_sessions, :status
    add_index :cash_sessions, :opened_at
    add_index :cash_sessions, :closed_at
    add_index :cash_sessions, :opened_by_id, unique: true, where: "status = 0", name: "index_open_cash_sessions_on_opened_by_id"
  end
end
