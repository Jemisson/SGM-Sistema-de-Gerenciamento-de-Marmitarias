FactoryBot.define do
  factory :sale_item do
    association :sale
    association :product
    quantity { 1 }
    unit_price { product&.sale_price || 9.99 }
    total_price { unit_price * quantity }
  end
end
