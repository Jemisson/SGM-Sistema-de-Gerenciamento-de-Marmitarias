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

def ensure_seed_cash_movement!(cash_session:, user:, movement_type:, amount:, description:, occurred_at:, source: nil)
  movement = CashMovement.find_or_initialize_by(
    cash_session: cash_session,
    movement_type: movement_type,
    description: description,
    occurred_at: occurred_at
  )
  movement.assign_attributes(
    user: user,
    amount: amount,
    source: source
  )
  movement.save!(validate: false)
  movement
end

def ensure_historical_cash_session!(user:, date:, opening_amount:)
  opened_at = Time.zone.local(date.year, date.month, date.day, 8, 0, 0)
  closed_at = Time.zone.local(date.year, date.month, date.day, 17, 40, 0)
  session = CashSession.find_or_initialize_by(opened_by: user, opened_at: opened_at)
  session.assign_attributes(
    opening_amount: opening_amount,
    closed_by: user,
    closing_amount: opening_amount,
    expected_amount: opening_amount,
    difference_amount: 0,
    closed_at: closed_at,
    status: :closed,
    notes: "Caixa historico seed #{date.iso8601}"
  )
  session.save!(validate: false)

  ensure_seed_cash_movement!(
    cash_session: session,
    user: user,
    movement_type: :opening,
    amount: opening_amount,
    description: "Abertura de caixa",
    occurred_at: opened_at
  )

  session
end

def ensure_historical_sale!(user:, cash_session:, sold_at:, payment_method:, items:, status: :confirmed)
  return if Sale.exists?(user: user, sold_at: sold_at)

  Sale.transaction do
    sale = Sale.new(
      cash_session: cash_session,
      user: user,
      payment_method: payment_method,
      status: status,
      sold_at: sold_at,
      total_amount: 0
    )

    items.each do |item|
      product = Product.includes(recipe: { recipe_items: :ingredient }).find(item.fetch(:product_id))
      quantity = item.fetch(:quantity)
      unit_price = item.fetch(:unit_price, product.sale_price)
      sale.sale_items.build(
        product: product,
        quantity: quantity,
        unit_price: unit_price,
        total_price: unit_price * quantity
      )
    end
    sale.total_amount = sale.sale_items.sum(&:total_price)
    sale.save!

    if sale.confirmed?
      ensure_seed_cash_movement!(
        cash_session: cash_session,
        user: user,
        movement_type: :sale,
        amount: sale.total_amount,
        description: "Venda ##{sale.id}",
        occurred_at: sold_at,
        source: sale
      )

      sale.sale_items.includes(product: { recipe: { recipe_items: :ingredient } }).each do |sale_item|
        sale_item.product.recipe.recipe_items.each do |recipe_item|
          StockMovement.find_or_create_by!(
            ingredient: recipe_item.ingredient,
            user: user,
            movement_type: :sale_consumption,
            source: sale,
            occurred_at: sold_at,
            reason: "Venda ##{sale.id}"
          ) do |movement|
            movement.quantity = recipe_item.quantity * sale_item.quantity
            movement.unit_cost = recipe_item.ingredient.purchase_price
          end
        end
      end
    end

    sale
  end
end

def ensure_historical_financial_entry!(user:, entry_type:, category:, description:, amount:, payment_method:, occurred_at:, cash_session: nil)
  entry = FinancialEntry.find_or_initialize_by(
    user: user,
    entry_type: entry_type,
    category: category,
    description: description,
    occurred_at: occurred_at
  )
  entry.assign_attributes(
    cash_session: cash_session,
    amount: amount,
    payment_method: payment_method,
    active: true
  )
  entry.save!

  if cash_session
    ensure_seed_cash_movement!(
      cash_session: cash_session,
      user: user,
      movement_type: entry.entry_type,
      amount: entry.amount,
      description: entry.description,
      occurred_at: entry.occurred_at,
      source: entry
    )
  end

  entry
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

pasta = upsert_ingredient!(
  code: "INS-MACARRAO",
  attributes: {
    name: "Macarrao penne",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 42,
    minimum_stock: 8,
    purchase_price: 6.8,
    manufacturing_date: today - 20.days,
    expiration_date: today + 240.days,
    received_at: today - 10.days,
    notes: "Massa para marmitas especiais."
  }
)

vegetables = upsert_ingredient!(
  code: "INS-LEGUMES",
  attributes: {
    name: "Legumes cozidos",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 24,
    minimum_stock: 6,
    purchase_price: 9.2,
    manufacturing_date: today - 1.day,
    expiration_date: today + 7.days,
    received_at: today - 1.day,
    notes: "Cenoura, abobrinha e brocolis."
  }
)

pork = upsert_ingredient!(
  code: "INS-LOMBO",
  attributes: {
    name: "Lombo suino",
    category: protein_category,
    supplier: meat_supplier,
    unit: "kg",
    current_stock: 22,
    minimum_stock: 5,
    purchase_price: 21.4,
    manufacturing_date: today - 2.days,
    expiration_date: today + 18.days,
    received_at: today - 2.days,
    notes: "Lombo para marmita executiva."
  }
)

sauce = upsert_ingredient!(
  code: "INS-MOLHO",
  attributes: {
    name: "Molho de tomate",
    category: side_category,
    supplier: market_supplier,
    unit: "kg",
    current_stock: 28,
    minimum_stock: 5,
    purchase_price: 7.1,
    manufacturing_date: today - 12.days,
    expiration_date: today + 120.days,
    received_at: today - 5.days,
    notes: "Molho base para pratos com massa."
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

fit_lunch = upsert_product!(
  code: "PROD-MARMITA-FIT",
  attributes: {
    name: "Marmita fit",
    description: "Frango, legumes cozidos, salada e arroz reduzido.",
    category: product_category,
    sale_price: 27.9
  }
)

pasta_lunch = upsert_product!(
  code: "PROD-MARMITA-MASSA",
  attributes: {
    name: "Marmita de massa",
    description: "Penne ao molho com carne bovina e legumes.",
    category: product_category,
    sale_price: 29.9
  }
)

pork_lunch = upsert_product!(
  code: "PROD-MARMITA-LOMBO",
  attributes: {
    name: "Marmita de lombo",
    description: "Arroz, feijao, lombo suino e legumes.",
    category: product_category,
    sale_price: 30.9
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

upsert_recipe!(
  product: fit_lunch,
  name: "Receita marmita fit",
  description: "Composicao padrao da marmita fit.",
  items: [
    { ingredient: rice, quantity: 0.120, unit: "kg" },
    { ingredient: chicken, quantity: 0.200, unit: "kg" },
    { ingredient: vegetables, quantity: 0.150, unit: "kg" },
    { ingredient: salad, quantity: 0.100, unit: "kg" }
  ]
)

upsert_recipe!(
  product: pasta_lunch,
  name: "Receita marmita de massa",
  description: "Composicao padrao da marmita de massa.",
  items: [
    { ingredient: pasta, quantity: 0.220, unit: "kg" },
    { ingredient: sauce, quantity: 0.100, unit: "kg" },
    { ingredient: beef, quantity: 0.120, unit: "kg" },
    { ingredient: vegetables, quantity: 0.080, unit: "kg" }
  ]
)

upsert_recipe!(
  product: pork_lunch,
  name: "Receita marmita de lombo",
  description: "Composicao padrao da marmita de lombo.",
  items: [
    { ingredient: rice, quantity: 0.180, unit: "kg" },
    { ingredient: beans, quantity: 0.120, unit: "kg" },
    { ingredient: pork, quantity: 0.180, unit: "kg" },
    { ingredient: vegetables, quantity: 0.100, unit: "kg" }
  ]
)

menu = upsert_menu!(
  name: "Cardapio da Semana",
  products: [chicken_lunch, beef_lunch, fit_lunch, pasta_lunch, pork_lunch]
)

products_for_history = [
  chicken_lunch,
  beef_lunch,
  fit_lunch,
  pasta_lunch,
  pork_lunch
]
payment_methods = %i[cash pix debit_card credit_card]
historical_start_date = today - 180.days
historical_end_date = today - 1.day

(historical_start_date..historical_end_date).each do |date|
  next if date.sunday?

  opening_amount = 120 + ((date.yday % 5) * 10)
  session = ensure_historical_cash_session!(user: cashier, date: date, opening_amount: opening_amount)
  daily_sales_count = 18 + ((date.yday + date.month) % 22)
  lunch_peak = Time.zone.local(date.year, date.month, date.day, 10, 45, 0)

  daily_sales_count.times do |index|
    product = products_for_history[(date.yday + index) % products_for_history.size]
    extra_product = products_for_history[(date.yday + index + 2) % products_for_history.size]
    quantity = 1 + ((date.yday + index) % 3 == 0 ? 1 : 0)
    sold_at = lunch_peak + (index * 9).minutes + ((date.yday + index) % 6).minutes
    items = [{ product_id: product.id, quantity: quantity }]

    if index % 11 == 0
      items << { product_id: extra_product.id, quantity: 1 }
    end

    ensure_historical_sale!(
      user: cashier,
      cash_session: session,
      sold_at: sold_at,
      payment_method: payment_methods[(date.yday + index) % payment_methods.size],
      items: items,
      status: index % 37 == 0 ? :canceled : :confirmed
    )
  end

  if date.monday?
    ensure_historical_financial_entry!(
      user: manager,
      entry_type: :expense,
      category: "Compras de insumos",
      description: "Reposicao semanal de insumos #{date.iso8601}",
      amount: 520 + ((date.yday % 4) * 85),
      payment_method: :bank_transfer,
      occurred_at: Time.zone.local(date.year, date.month, date.day, 9, 30, 0)
    )

    [rice, beans, chicken, beef, salad, pasta, vegetables, pork, sauce].each_with_index do |ingredient, index|
      StockMovement.find_or_create_by!(
        ingredient: ingredient,
        user: manager,
        movement_type: :entry,
        occurred_at: Time.zone.local(date.year, date.month, date.day, 9, 15, index),
        reason: "Reposicao semanal seed #{date.iso8601}"
      ) do |movement|
        movement.quantity = 18 + ((date.yday + index) % 12)
        movement.unit_cost = ingredient.purchase_price
      end
    end
  end

  if date.day == 5
    ensure_historical_financial_entry!(
      user: manager,
      entry_type: :expense,
      category: "Folha de pagamento",
      description: "Pagamento da equipe #{date.strftime('%m/%Y')}",
      amount: 4_800 + (date.month * 75),
      payment_method: :bank_transfer,
      occurred_at: Time.zone.local(date.year, date.month, date.day, 16, 0, 0)
    )
  end

  if date.day == 10
    ensure_historical_financial_entry!(
      user: manager,
      entry_type: :expense,
      category: "Aluguel",
      description: "Aluguel da cozinha #{date.strftime('%m/%Y')}",
      amount: 2_300,
      payment_method: :bank_transfer,
      occurred_at: Time.zone.local(date.year, date.month, date.day, 15, 0, 0)
    )
  end

  if date.day == 20
    ensure_historical_financial_entry!(
      user: manager,
      entry_type: :income,
      category: "Encomendas corporativas",
      description: "Contrato empresarial #{date.strftime('%m/%Y')}",
      amount: 1_200 + (date.month * 45),
      payment_method: :pix,
      occurred_at: Time.zone.local(date.year, date.month, date.day, 14, 0, 0)
    )
  end

  session.reload
  movement_total = session.cash_movements.where(movement_type: %i[sale income expense adjustment]).sum do |movement|
    multiplier = %w[sale income adjustment].include?(movement.movement_type) ? 1 : -1
    movement.amount * multiplier
  end
  expected_amount = session.opening_amount + movement_total
  session.update_columns(
    closing_amount: expected_amount,
    expected_amount: expected_amount,
    difference_amount: 0,
    updated_at: Time.current
  )

  ensure_seed_cash_movement!(
    cash_session: session,
    user: cashier,
    movement_type: :closing,
    amount: expected_amount,
    description: "Fechamento de caixa",
    occurred_at: Time.zone.local(date.year, date.month, date.day, 17, 40, 0)
  )
end

ensure_seed_stock!(
  rice => 1_100,
  beans => 800,
  chicken => 900,
  beef => 700,
  salad => 450,
  pasta => 600,
  vegetables => 500,
  pork => 500,
  sauce => 420
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
