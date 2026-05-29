# Seeds de desenvolvimento para o SGM - Sistema de Gerenciamento para Marmitaria.
# O arquivo e idempotente: cadastros-base sao localizados por chaves naturais e
# vendas de exemplo usam horarios fixos no dia atual para evitar duplicidade.

password = "password123"

def upsert_user!(email:, name:, cpf:, role:)
  user = User.find_by(email: email) || User.find_by(cpf: cpf) || User.new
  user.assign_attributes(
    email: email,
    name: name,
    cpf: cpf,
    phone: "44999999999",
    role: role,
    gender: "not_informed",
    marital_status: "not_informed",
    active: true,
    street: "Avenida Colombo",
    number: "5790",
    neighborhood: "Zona 7",
    city: "Maringa",
    state: "PR",
    zip_code: "87020900",
    password: "password123",
    password_confirmation: "password123"
  )
  user.save!
  user
end

def upsert_category!(name:, description:)
  Category.find_or_initialize_by(name: name).tap do |category|
    category.assign_attributes(description: description, active: true)
    category.save!
  end
end

def upsert_supplier!(cnpj:, attributes:)
  Supplier.find_or_initialize_by(cnpj: cnpj).tap do |supplier|
    supplier.assign_attributes(attributes.merge(active: true))
    supplier.save!
  end
end

def upsert_ingredient!(code:, attributes:)
  ingredient = Ingredient.find_or_initialize_by(code: code)
  stock_attributes = ingredient.new_record? ? {} : attributes.slice(:current_stock)
  ingredient.assign_attributes(attributes.except(*stock_attributes.keys).merge(active: true))
  ingredient.current_stock = attributes[:current_stock] if ingredient.new_record?
  ingredient.save!
  ingredient
end

def upsert_product!(code:, attributes:)
  Product.find_or_initialize_by(code: code).tap do |product|
    product.assign_attributes(attributes.merge(active: true))
    product.save!
  end
end

def upsert_recipe!(product:, name:, description:, items:)
  recipe = Recipe.find_or_initialize_by(product: product)
  recipe.assign_attributes(name: name, description: description, active: true)

  ingredients = items.map { |item| item.fetch(:ingredient) }
  recipe.recipe_items.each do |recipe_item|
    recipe_item.mark_for_destruction unless ingredients.include?(recipe_item.ingredient)
  end

  items.each do |item|
    recipe_item = recipe.recipe_items.detect { |current| current.ingredient == item.fetch(:ingredient) } ||
                  recipe.recipe_items.build(ingredient: item.fetch(:ingredient))
    recipe_item.assign_attributes(quantity: item.fetch(:quantity), unit: item.fetch(:unit))
  end

  recipe.save!
  recipe
end

def upsert_menu!(name:, products:)
  menu = Menu.find_or_initialize_by(name: name)
  menu.assign_attributes(
    start_date: Date.current.beginning_of_week,
    end_date: Date.current.end_of_week,
    status: :active,
    active: true
  )

  menu.menu_items.each do |menu_item|
    menu_item.mark_for_destruction unless products.include?(menu_item.product)
  end

  products.each do |product|
    menu_item = menu.menu_items.detect { |current| current.product == product } ||
                menu.menu_items.build(product: product)
    menu_item.assign_attributes(available: true, price_override: nil)
  end

  menu.save!
  menu
end

def ensure_seed_sale!(user:, cash_session:, sold_at:, payment_method:, items:)
  return if Sale.exists?(user: user, sold_at: sold_at)

  SaleCreator.call(
    user: user,
    cash_session_id: cash_session.id,
    payment_method: payment_method,
    sold_at: sold_at,
    items: items
  )
end

def ensure_seed_stock!(requirements)
  requirements.each do |ingredient, minimum_quantity|
    next if ingredient.current_stock >= minimum_quantity

    ingredient.update!(current_stock: minimum_quantity)
  end
end

admin = upsert_user!(
  email: "admin@example.com",
  name: "Administrador SGM",
  cpf: "00000000000",
  role: :admin
)

manager = upsert_user!(
  email: "manager@example.com",
  name: "Gerente SGM",
  cpf: "11111111111",
  role: :manager
)

cashier = upsert_user!(
  email: "cashier@example.com",
  name: "Caixa SGM",
  cpf: "22222222222",
  role: :cashier
)

protein_category = upsert_category!(
  name: "Proteinas",
  description: "Carnes e preparos principais das marmitas."
)
side_category = upsert_category!(
  name: "Acompanhamentos",
  description: "Graos, massas, legumes e guarnicoes."
)
product_category = upsert_category!(
  name: "Marmitas",
  description: "Produtos finais vendidos no balcao."
)

meat_supplier = upsert_supplier!(
  cnpj: "12345678000190",
  attributes: {
    name: "Distribuidora Carnes Maringa",
    phone: "4433331000",
    email: "vendas@carnesmaringa.example.com",
    street: "Rua das Industrias",
    number: "100",
    neighborhood: "Parque Industrial",
    city: "Maringa",
    state: "PR",
    zip_code: "87000000"
  }
)

market_supplier = upsert_supplier!(
  cnpj: "98765432000110",
  attributes: {
    name: "Atacado Graos e Verduras",
    phone: "4433332000",
    email: "contato@graoseverduras.example.com",
    street: "Avenida Brasil",
    number: "2000",
    neighborhood: "Centro",
    city: "Maringa",
    state: "PR",
    zip_code: "87010000"
  }
)

today = Date.current

rice = upsert_ingredient!(
  code: "INS-ARROZ",
  attributes: {
    name: "Arroz branco",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 50,
    minimum_stock: 10,
    purchase_price: 5.9,
    manufacturing_date: today - 5.days,
    expiration_date: today + 180.days,
    received_at: today - 3.days,
    notes: "Pacote de arroz tipo 1."
  }
)

beans = upsert_ingredient!(
  code: "INS-FEIJAO",
  attributes: {
    name: "Feijao carioca",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 35,
    minimum_stock: 8,
    purchase_price: 8.5,
    manufacturing_date: today - 5.days,
    expiration_date: today + 180.days,
    received_at: today - 3.days,
    notes: "Feijao para preparo diario."
  }
)

chicken = upsert_ingredient!(
  code: "INS-FRANGO",
  attributes: {
    name: "Peito de frango",
    category: protein_category,
    supplier: meat_supplier,
    unit: "kg",
    current_stock: 30,
    minimum_stock: 6,
    purchase_price: 16.9,
    manufacturing_date: today - 2.days,
    expiration_date: today + 20.days,
    received_at: today - 2.days,
    notes: "Frango resfriado."
  }
)

beef = upsert_ingredient!(
  code: "INS-CARNE",
  attributes: {
    name: "Carne bovina em cubos",
    category: protein_category,
    supplier: meat_supplier,
    unit: "kg",
    current_stock: 25,
    minimum_stock: 5,
    purchase_price: 29.9,
    manufacturing_date: today - 2.days,
    expiration_date: today + 20.days,
    received_at: today - 2.days,
    notes: "Carne para marmita tradicional."
  }
)

salad = upsert_ingredient!(
  code: "INS-SALADA",
  attributes: {
    name: "Mix de salada",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 15,
    minimum_stock: 3,
    purchase_price: 7.5,
    manufacturing_date: today - 1.day,
    expiration_date: today + 5.days,
    received_at: today - 1.day,
    notes: "Legumes e folhas para salada."
  }
)

chicken_lunch = upsert_product!(
  code: "PROD-MARMITA-FRANGO",
  attributes: {
    name: "Marmita de frango",
    description: "Arroz, feijao, frango grelhado e salada.",
    category: product_category,
    sale_price: 24.9
  }
)

beef_lunch = upsert_product!(
  code: "PROD-MARMITA-CARNE",
  attributes: {
    name: "Marmita de carne",
    description: "Arroz, feijao, carne em cubos e salada.",
    category: product_category,
    sale_price: 28.9
  }
)

upsert_recipe!(
  product: chicken_lunch,
  name: "Receita marmita de frango",
  description: "Composicao padrao da marmita de frango.",
  items: [
    { ingredient: rice, quantity: 0.180, unit: "kg" },
    { ingredient: beans, quantity: 0.120, unit: "kg" },
    { ingredient: chicken, quantity: 0.180, unit: "kg" },
    { ingredient: salad, quantity: 0.080, unit: "kg" }
  ]
)

upsert_recipe!(
  product: beef_lunch,
  name: "Receita marmita de carne",
  description: "Composicao padrao da marmita de carne.",
  items: [
    { ingredient: rice, quantity: 0.180, unit: "kg" },
    { ingredient: beans, quantity: 0.120, unit: "kg" },
    { ingredient: beef, quantity: 0.180, unit: "kg" },
    { ingredient: salad, quantity: 0.080, unit: "kg" }
  ]
)

menu = upsert_menu!(
  name: "Cardapio da Semana",
  products: [chicken_lunch, beef_lunch]
)

first_sale_at = Time.zone.now.change(hour: 11, min: 30, sec: 0)
second_sale_at = Time.zone.now.change(hour: 12, min: 15, sec: 0)

cash_session = cashier.opened_cash_sessions.opened.order(opened_at: :desc, id: :desc).first ||
               CashSessionOpener.call(
                 user: cashier,
                 opening_amount: 150,
                 notes: "Caixa aberto pelos seeds de desenvolvimento.",
                 opened_at: Time.zone.now.change(hour: 8, min: 0, sec: 0)
               )

unless Sale.exists?(user: cashier, sold_at: first_sale_at) && Sale.exists?(user: cashier, sold_at: second_sale_at)
  ensure_seed_stock!(
    rice => 50,
    beans => 35,
    chicken => 30,
    beef => 25,
    salad => 15
  )
end

ensure_seed_sale!(
  user: cashier,
  cash_session: cash_session,
  sold_at: first_sale_at,
  payment_method: :pix,
  items: [
    { product_id: chicken_lunch.id, quantity: 2 },
    { product_id: beef_lunch.id, quantity: 1 }
  ]
)

ensure_seed_sale!(
  user: cashier,
  cash_session: cash_session,
  sold_at: second_sale_at,
  payment_method: :cash,
  items: [
    { product_id: chicken_lunch.id, quantity: 1 }
  ]
)

puts "Seeds de desenvolvimento criados/atualizados com sucesso."
puts "Usuarios: #{[admin.email, manager.email, cashier.email].join(', ')}"
puts "Senha padrao: #{password}"
puts "Categorias: #{Category.count} | Fornecedores: #{Supplier.count} | Insumos: #{Ingredient.count}"
puts "Produtos: #{Product.count} | Receitas: #{Recipe.count} | Cardapios: #{Menu.count}"
puts "Caixa aberto do cashier: ##{cash_session.id} | Vendas: #{Sale.count}"
