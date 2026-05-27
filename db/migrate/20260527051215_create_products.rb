class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true
      t.decimal :sale_price, precision: 10, scale: 2, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :products, :code, unique: true
    add_index :products, :name
    add_index :products, :active
  end
end
