class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :recipes, :name
    add_index :recipes, :active
    add_index :recipes, :product_id, unique: true, where: "active = true", name: "index_active_recipes_on_product_id"
  end
end
