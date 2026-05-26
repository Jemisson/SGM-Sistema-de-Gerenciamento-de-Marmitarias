class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.date :birth_date
      t.string :cpf, null: false
      t.string :phone
      t.integer :role, null: false
      t.string :gender
      t.string :marital_status
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :jti, null: false
      t.boolean :active, null: false, default: true
      t.string :street
      t.string :number
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :zip_code

      t.timestamps
    end

    add_index :users, :cpf, unique: true
    add_index :users, :email, unique: true
    add_index :users, :jti, unique: true
  end
end
