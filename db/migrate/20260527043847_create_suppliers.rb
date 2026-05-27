class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :cnpj, null: false
      t.string :phone
      t.string :email
      t.string :street
      t.string :number
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :zip_code
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :suppliers, :cnpj, unique: true
    add_index :suppliers, :name
    add_index :suppliers, :active
  end
end
