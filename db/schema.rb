# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_27_044707) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["occurred_at"], name: "index_audit_logs_on_occurred_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_categories_on_active"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.decimal "current_stock", precision: 12, scale: 3, default: "0.0", null: false
    t.date "expiration_date"
    t.date "manufacturing_date"
    t.decimal "minimum_stock", precision: 12, scale: 3, default: "0.0", null: false
    t.string "name", null: false
    t.text "notes"
    t.decimal "purchase_price", precision: 10, scale: 2
    t.date "received_at"
    t.bigint "supplier_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_ingredients_on_active"
    t.index ["category_id", "active"], name: "index_ingredients_on_category_id_and_active"
    t.index ["category_id"], name: "index_ingredients_on_category_id"
    t.index ["code"], name: "index_ingredients_on_code", unique: true
    t.index ["name"], name: "index_ingredients_on_name"
    t.index ["supplier_id", "active"], name: "index_ingredients_on_supplier_id_and_active"
    t.index ["supplier_id"], name: "index_ingredients_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "city"
    t.string "cnpj", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "neighborhood"
    t.string "number"
    t.string "phone"
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["active"], name: "index_suppliers_on_active"
    t.index ["cnpj"], name: "index_suppliers_on_cnpj", unique: true
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.date "birth_date"
    t.string "city"
    t.string "cpf", null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "gender"
    t.string "jti", null: false
    t.string "marital_status"
    t.string "name", null: false
    t.string "neighborhood"
    t.string "number"
    t.string "phone"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", null: false
    t.string "state"
    t.string "street"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["cpf"], name: "index_users_on_cpf", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "audit_logs", "users"
  add_foreign_key "ingredients", "categories"
  add_foreign_key "ingredients", "suppliers"
end
