class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :status, null: false, default: 0
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :menus, :name
    add_index :menus, :status
    add_index :menus, :active
    add_index :menus, [:start_date, :end_date]
  end
end
