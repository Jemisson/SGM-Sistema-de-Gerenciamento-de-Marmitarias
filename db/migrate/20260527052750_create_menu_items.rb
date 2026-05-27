class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.boolean :available, default: true, null: false
      t.decimal :price_override, precision: 10, scale: 2

      t.timestamps
    end

    add_index :menu_items, [:menu_id, :product_id], unique: true
  end
end
