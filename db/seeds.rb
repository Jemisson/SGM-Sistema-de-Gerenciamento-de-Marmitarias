# Seeds de desenvolvimento para o SGM - Sistema de Gerenciamento para Marmitaria.
# O arquivo e idempotente: cadastros-base sao localizados por chaves naturais e
# vendas de exemplo usam horarios fixos no dia atual para evitar duplicidade.

require "faker"

password = "password123"
Faker::Config.random = Random.new(42)

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

def upsert_period_menu!(name:, start_date:, end_date:, products:)
  menu = Menu.find_or_initialize_by(name: name)
  menu.assign_attributes(
    start_date: start_date,
    end_date: end_date,
    status: end_date < Date.current ? :inactive : :active,
    active: true
  )

  menu.menu_items.each do |menu_item|
    menu_item.mark_for_destruction unless products.include?(menu_item.product)
  end

  products.each_with_index do |product, index|
    menu_item = menu.menu_items.detect { |current| current.product == product } ||
                menu.menu_items.build(product: product)
    menu_item.assign_attributes(
      available: true,
      price_override: index % 5 == 0 ? product.sale_price + 2 : nil
    )
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
beverage_category = upsert_category!(
  name: "Bebidas",
  description: "Bebidas vendidas junto com as marmitas."
)
dessert_category = upsert_category!(
  name: "Sobremesas",
  description: "Doces e sobremesas individuais."
)
packaging_category = upsert_category!(
  name: "Embalagens",
  description: "Embalagens, descartaveis e itens de entrega."
)
seasoning_category = upsert_category!(
  name: "Temperos",
  description: "Temperos secos, molhos e condimentos."
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

extra_suppliers = [
  ["11222333000101", "Hortifruti Norte Parana", "hortifruti"],
  ["11222333000102", "Cooperativa Graos do Sul", "graos"],
  ["11222333000103", "Laticinios Campo Verde", "laticinios"],
  ["11222333000104", "Avicola Bom Corte", "avicola"],
  ["11222333000105", "Embalagens Noroeste", "embalagens"],
  ["11222333000106", "Bebidas Avenida", "bebidas"],
  ["11222333000107", "Temperos Casa Cheia", "temperos"],
  ["11222333000108", "Doces da Vila", "doces"]
].map.with_index do |(cnpj, name, slug), index|
  upsert_supplier!(
    cnpj: cnpj,
    attributes: {
      name: name,
      phone: "44#{Faker::Number.number(digits: 8)}",
      email: "contato@#{slug}.example.com",
      street: Faker::Address.street_name,
      number: (100 + index * 37).to_s,
      neighborhood: ["Centro", "Zona 7", "Vila Operaria", "Jardim Alvorada"].fetch(index % 4),
      city: "Maringa",
      state: "PR",
      zip_code: "870#{Faker::Number.number(digits: 5)}"
    }
  )
end

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

extra_ingredient_specs = [
  ["INS-BATATA", "Batata inglesa", side_category, extra_suppliers[0], 7.4, 80, 12, 45],
  ["INS-MANDIOCA", "Mandioca descascada", side_category, extra_suppliers[0], 8.9, 70, 10, 35],
  ["INS-PURE", "Flocos para pure", side_category, extra_suppliers[1], 11.5, 55, 8, 180],
  ["INS-FAROFA", "Farofa temperada", side_category, extra_suppliers[1], 9.6, 50, 7, 210],
  ["INS-LENTILHA", "Lentilha", side_category, extra_suppliers[1], 12.8, 45, 7, 240],
  ["INS-GRAO-BICO", "Grao de bico", side_category, extra_suppliers[1], 13.5, 42, 6, 240],
  ["INS-QUINOA", "Quinoa em graos", side_category, extra_suppliers[1], 21.9, 34, 5, 180],
  ["INS-BROCOLIS", "Brocolis congelado", side_category, extra_suppliers[0], 14.2, 38, 6, 120],
  ["INS-COUVE", "Couve fatiada", side_category, extra_suppliers[0], 6.7, 30, 5, 8],
  ["INS-ABOBORA", "Abobora cabotia", side_category, extra_suppliers[0], 5.8, 52, 8, 25],
  ["INS-PATINHO", "Patinho moido", protein_category, meat_supplier, 32.5, 48, 8, 18],
  ["INS-COSTELA", "Costela bovina desfiada", protein_category, meat_supplier, 27.9, 36, 6, 15],
  ["INS-FILE-TILAPIA", "File de tilapia", protein_category, extra_suppliers[3], 34.9, 34, 6, 16],
  ["INS-OVO", "Ovo cozido", protein_category, extra_suppliers[3], 14.4, 28, 5, 20],
  ["INS-QUEIJO", "Queijo mussarela", protein_category, extra_suppliers[2], 31.2, 25, 4, 30],
  ["INS-CREME-LEITE", "Creme de leite", side_category, extra_suppliers[2], 9.8, 40, 6, 120],
  ["INS-CURRY", "Molho curry", seasoning_category, extra_suppliers[6], 15.7, 30, 5, 180],
  ["INS-BARBECUE", "Molho barbecue", seasoning_category, extra_suppliers[6], 12.6, 32, 5, 180],
  ["INS-ERVAS", "Mix de ervas", seasoning_category, extra_suppliers[6], 18.9, 20, 3, 240],
  ["INS-MARMITEX-P", "Embalagem marmitex P", packaging_category, extra_suppliers[4], 0.62, 800, 120, 365],
  ["INS-MARMITEX-M", "Embalagem marmitex M", packaging_category, extra_suppliers[4], 0.74, 900, 150, 365],
  ["INS-MARMITEX-G", "Embalagem marmitex G", packaging_category, extra_suppliers[4], 0.88, 650, 100, 365],
  ["INS-COPO", "Copo descartavel", packaging_category, extra_suppliers[4], 0.18, 1_200, 200, 365],
  ["INS-GUARDANAPO", "Guardanapo", packaging_category, extra_suppliers[4], 0.04, 2_500, 400, 365]
].map do |code, name, category, supplier, purchase_price, current_stock, minimum_stock, expires_in|
  upsert_ingredient!(
    code: code,
    attributes: {
      name: name,
      category: category,
      supplier: supplier,
      unit: category == packaging_category ? "un" : "kg",
      current_stock: current_stock,
      minimum_stock: minimum_stock,
      purchase_price: purchase_price,
      manufacturing_date: today - ((code.sum % 20) + 10).days,
      expiration_date: today + expires_in.days,
      received_at: today - ((code.sum % 8) + 1).days,
      notes: "Insumo gerado pelo seed para ampliar dados de relatorios."
    }
  )
end

ingredients_by_code = Ingredient.where(code: [
  "INS-BATATA", "INS-MANDIOCA", "INS-PURE", "INS-FAROFA", "INS-LENTILHA",
  "INS-GRAO-BICO", "INS-QUINOA", "INS-BROCOLIS", "INS-COUVE", "INS-ABOBORA",
  "INS-PATINHO", "INS-COSTELA", "INS-FILE-TILAPIA", "INS-OVO", "INS-QUEIJO",
  "INS-CREME-LEITE", "INS-CURRY", "INS-BARBECUE", "INS-ERVAS",
  "INS-MARMITEX-P", "INS-MARMITEX-M", "INS-MARMITEX-G"
]).index_by(&:code)

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

extra_product_specs = [
  ["PROD-MARMITA-PATINHO", "Marmita de patinho", "Arroz, lentilha, patinho moido e couve.", 31.9, [[rice, 0.160], [ingredients_by_code["INS-LENTILHA"], 0.120], [ingredients_by_code["INS-PATINHO"], 0.180], [ingredients_by_code["INS-COUVE"], 0.070]]],
  ["PROD-MARMITA-TILAPIA", "Marmita de tilapia", "Tilapia grelhada com quinoa, legumes e salada.", 34.9, [[ingredients_by_code["INS-QUINOA"], 0.130], [ingredients_by_code["INS-FILE-TILAPIA"], 0.180], [vegetables, 0.120], [salad, 0.080]]],
  ["PROD-MARMITA-COSTELA", "Marmita de costela", "Costela desfiada, mandioca, arroz e farofa.", 33.9, [[rice, 0.140], [ingredients_by_code["INS-MANDIOCA"], 0.160], [ingredients_by_code["INS-COSTELA"], 0.180], [ingredients_by_code["INS-FAROFA"], 0.050]]],
  ["PROD-MARMITA-STROGONOFF", "Marmita strogonoff", "Frango ao creme, arroz e batata.", 30.9, [[rice, 0.180], [chicken, 0.170], [ingredients_by_code["INS-CREME-LEITE"], 0.080], [ingredients_by_code["INS-BATATA"], 0.120]]],
  ["PROD-MARMITA-CURRY", "Marmita curry de frango", "Frango ao curry com grao de bico e legumes.", 32.9, [[chicken, 0.180], [ingredients_by_code["INS-CURRY"], 0.050], [ingredients_by_code["INS-GRAO-BICO"], 0.120], [vegetables, 0.120]]],
  ["PROD-MARMITA-BARBECUE", "Marmita barbecue", "Lombo ao barbecue, arroz, feijao e abobora.", 32.5, [[rice, 0.160], [beans, 0.110], [pork, 0.180], [ingredients_by_code["INS-BARBECUE"], 0.050], [ingredients_by_code["INS-ABOBORA"], 0.090]]],
  ["PROD-MARMITA-OMELETE", "Marmita omelete", "Ovo, queijo, legumes e salada.", 25.9, [[ingredients_by_code["INS-OVO"], 0.180], [ingredients_by_code["INS-QUEIJO"], 0.060], [vegetables, 0.130], [salad, 0.090]]],
  ["PROD-MARMITA-VEGETARIANA", "Marmita vegetariana", "Grao de bico, quinoa, brocolis e salada.", 28.9, [[ingredients_by_code["INS-GRAO-BICO"], 0.150], [ingredients_by_code["INS-QUINOA"], 0.120], [ingredients_by_code["INS-BROCOLIS"], 0.120], [salad, 0.080]]],
  ["PROD-MARMITA-EXECUTIVA-G", "Marmita executiva grande", "Arroz, feijao, carne, frango e legumes.", 38.9, [[rice, 0.220], [beans, 0.150], [beef, 0.140], [chicken, 0.130], [vegetables, 0.120]]],
  ["PROD-MARMITA-EXECUTIVA-P", "Marmita executiva pequena", "Porcao reduzida de arroz, feijao, proteina e salada.", 21.9, [[rice, 0.120], [beans, 0.080], [chicken, 0.110], [salad, 0.060]]],
  ["PROD-MARMITA-BROCOLIS", "Marmita frango com brocolis", "Frango, arroz, brocolis e ervas.", 29.9, [[rice, 0.160], [chicken, 0.180], [ingredients_by_code["INS-BROCOLIS"], 0.130], [ingredients_by_code["INS-ERVAS"], 0.015]]],
  ["PROD-MARMITA-PURE", "Marmita carne com pure", "Carne bovina com pure e legumes.", 31.5, [[beef, 0.180], [ingredients_by_code["INS-PURE"], 0.160], [vegetables, 0.120], [sauce, 0.050]]],
  ["PROD-MARMITA-PENNE-FRANGO", "Penne com frango", "Penne ao molho com frango e queijo.", 30.5, [[pasta, 0.220], [sauce, 0.100], [chicken, 0.150], [ingredients_by_code["INS-QUEIJO"], 0.050]]],
  ["PROD-MARMITA-LENTILHA", "Marmita de lentilha", "Arroz, lentilha, ovo e couve.", 26.9, [[rice, 0.150], [ingredients_by_code["INS-LENTILHA"], 0.150], [ingredients_by_code["INS-OVO"], 0.100], [ingredients_by_code["INS-COUVE"], 0.070]]],
  ["PROD-MARMITA-ABOBORA", "Marmita lombo com abobora", "Lombo, abobora, arroz e salada.", 30.9, [[pork, 0.180], [ingredients_by_code["INS-ABOBORA"], 0.150], [rice, 0.140], [salad, 0.070]]]
]

extra_products = extra_product_specs.map do |code, name, description, sale_price, recipe_items|
  product = upsert_product!(
    code: code,
    attributes: {
      name: name,
      description: description,
      category: product_category,
      sale_price: sale_price
    }
  )

  upsert_recipe!(
    product: product,
    name: "Receita #{name.downcase}",
    description: "Composicao padrao de #{name.downcase}.",
    items: recipe_items.map { |ingredient, quantity| { ingredient: ingredient, quantity: quantity, unit: ingredient.unit } }
  )

  product
end

menu = upsert_menu!(
  name: "Cardapio da Semana",
  products: [chicken_lunch, beef_lunch, fit_lunch, pasta_lunch, pork_lunch, *extra_products.first(10)]
)

products_for_history = [
  chicken_lunch,
  beef_lunch,
  fit_lunch,
  pasta_lunch,
  pork_lunch,
  *extra_products
]
all_ingredients_for_history = [rice, beans, chicken, beef, salad, pasta, vegetables, pork, sauce, *extra_ingredient_specs]
payment_methods = %i[cash pix debit_card credit_card]
historical_start_date = today - 180.days
historical_end_date = today - 1.day

(historical_start_date.beginning_of_week..historical_end_date).step(7).each_with_index do |week_start, index|
  week_end = [week_start + 5.days, historical_end_date].min
  next if week_end < historical_start_date

  weekly_products = products_for_history.rotate(index % products_for_history.size).first(8 + (index % 8))
  upsert_period_menu!(
    name: "Cardapio historico #{week_start.iso8601}",
    start_date: week_start,
    end_date: week_end,
    products: weekly_products
  )
end

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

  extra_sales_count = 10 + (date.yday % 9)
  dinner_peak = Time.zone.local(date.year, date.month, date.day, 14, 10, 0)

  extra_sales_count.times do |index|
    product = products_for_history[(date.yday * 3 + index * 2) % products_for_history.size]
    extra_product = products_for_history[(date.yday + index + 7) % products_for_history.size]
    quantity = 1 + ((date.wday + index) % 5 == 0 ? 1 : 0)
    sold_at = dinner_peak + (index * 7).minutes + ((date.yday + index) % 4).minutes
    items = [{ product_id: product.id, quantity: quantity }]
    items << { product_id: extra_product.id, quantity: 1 } if index % 6 == 0

    ensure_historical_sale!(
      user: cashier,
      cash_session: session,
      sold_at: sold_at,
      payment_method: payment_methods[(date.yday + index + 1) % payment_methods.size],
      items: items,
      status: index % 43 == 0 ? :canceled : :confirmed
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

    all_ingredients_for_history.each_with_index do |ingredient, index|
      StockMovement.find_or_create_by!(
        ingredient: ingredient,
        user: manager,
        movement_type: :entry,
        occurred_at: Time.zone.local(date.year, date.month, date.day, 9, 15, index),
        reason: "Reposicao semanal seed #{date.iso8601}"
      ) do |movement|
        movement.quantity = ingredient.unit == "un" ? 120 + ((date.yday + index) % 90) : 18 + ((date.yday + index) % 12)
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
  all_ingredients_for_history.index_with { |ingredient| ingredient.unit == "un" ? 1_500 : 700 }
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
