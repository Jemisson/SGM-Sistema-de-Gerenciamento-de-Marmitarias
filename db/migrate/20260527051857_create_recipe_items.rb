class CreateRecipeItems < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_items do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.string :unit, null: false

      t.timestamps
    end

    add_index :recipe_items, [:recipe_id, :ingredient_id], unique: true
  end
end
