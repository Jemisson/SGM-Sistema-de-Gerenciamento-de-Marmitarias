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

ActiveRecord::Schema[8.1].define(version: 2026_05_27_211455) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "cash_movements", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "cash_session_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "movement_type", null: false
    t.datetime "occurred_at", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cash_session_id"], name: "index_cash_movements_on_cash_session_id"
    t.index ["movement_type"], name: "index_cash_movements_on_movement_type"
    t.index ["occurred_at"], name: "index_cash_movements_on_occurred_at"
    t.index ["source_type", "source_id"], name: "index_cash_movements_on_source_type_and_source_id"
    t.index ["user_id"], name: "index_cash_movements_on_user_id"
  end

  create_table "cash_sessions", force: :cascade do |t|
    t.datetime "closed_at"
    t.bigint "closed_by_id"
    t.decimal "closing_amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.decimal "difference_amount", precision: 10, scale: 2
    t.decimal "expected_amount", precision: 10, scale: 2
    t.text "notes"
    t.datetime "opened_at", null: false
    t.bigint "opened_by_id", null: false
    t.decimal "opening_amount", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["closed_at"], name: "index_cash_sessions_on_closed_at"
    t.index ["closed_by_id"], name: "index_cash_sessions_on_closed_by_id"
    t.index ["opened_at"], name: "index_cash_sessions_on_opened_at"
    t.index ["opened_by_id"], name: "index_cash_sessions_on_opened_by_id"
    t.index ["opened_by_id"], name: "index_open_cash_sessions_on_opened_by_id", unique: true, where: "(status = 0)"
    t.index ["status"], name: "index_cash_sessions_on_status"
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

  create_table "financial_entries", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.bigint "cash_session_id"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "entry_type", null: false
    t.datetime "occurred_at", null: false
    t.integer "payment_method", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["active"], name: "index_financial_entries_on_active"
    t.index ["cash_session_id"], name: "index_financial_entries_on_cash_session_id"
    t.index ["category"], name: "index_financial_entries_on_category"
    t.index ["entry_type"], name: "index_financial_entries_on_entry_type"
    t.index ["occurred_at"], name: "index_financial_entries_on_occurred_at"
    t.index ["payment_method"], name: "index_financial_entries_on_payment_method"
    t.index ["source_type", "source_id"], name: "index_financial_entries_on_source_type_and_source_id"
    t.index ["user_id"], name: "index_financial_entries_on_user_id"
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

  create_table "menu_items", force: :cascade do |t|
    t.boolean "available", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "menu_id", null: false
    t.decimal "price_override", precision: 10, scale: 2
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "product_id"], name: "index_menu_items_on_menu_id_and_product_id", unique: true
    t.index ["menu_id"], name: "index_menu_items_on_menu_id"
    t.index ["product_id"], name: "index_menu_items_on_product_id"
  end

  create_table "menus", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "name", null: false
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_menus_on_active"
    t.index ["name"], name: "index_menus_on_name"
    t.index ["start_date", "end_date"], name: "index_menus_on_start_date_and_end_date"
    t.index ["status"], name: "index_menus_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "sale_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["code"], name: "index_products_on_code", unique: true
    t.index ["name"], name: "index_products_on_name"
  end

  create_table "recipe_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.bigint "recipe_id", null: false
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_items_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_items_on_recipe_id_and_ingredient_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_items_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_recipes_on_active"
    t.index ["name"], name: "index_recipes_on_name"
    t.index ["product_id"], name: "index_active_recipes_on_product_id", unique: true, where: "(active = true)"
    t.index ["product_id"], name: "index_recipes_on_product_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.bigint "sale_id", null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "cash_session_id", null: false
    t.datetime "created_at", null: false
    t.integer "payment_method", null: false
    t.datetime "sold_at", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["cash_session_id"], name: "index_sales_on_cash_session_id"
    t.index ["payment_method"], name: "index_sales_on_payment_method"
    t.index ["sold_at"], name: "index_sales_on_sold_at"
    t.index ["status"], name: "index_sales_on_status"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.integer "movement_type", null: false
    t.datetime "occurred_at", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.text "reason"
    t.bigint "source_id"
    t.string "source_type"
    t.decimal "unit_cost", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ingredient_id"], name: "index_stock_movements_on_ingredient_id"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["occurred_at"], name: "index_stock_movements_on_occurred_at"
    t.index ["source_type", "source_id"], name: "index_stock_movements_on_source_type_and_source_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "cash_movements", "cash_sessions"
  add_foreign_key "cash_movements", "users"
  add_foreign_key "cash_sessions", "users", column: "closed_by_id"
  add_foreign_key "cash_sessions", "users", column: "opened_by_id"
  add_foreign_key "financial_entries", "cash_sessions"
  add_foreign_key "financial_entries", "users"
  add_foreign_key "ingredients", "categories"
  add_foreign_key "ingredients", "suppliers"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "menu_items", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "recipe_items", "ingredients"
  add_foreign_key "recipe_items", "recipes"
  add_foreign_key "recipes", "products"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "cash_sessions"
  add_foreign_key "sales", "users"
  add_foreign_key "stock_movements", "ingredients"
  add_foreign_key "stock_movements", "users"
end
