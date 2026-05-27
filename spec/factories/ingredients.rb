FactoryBot.define do
  factory :ingredient do
    sequence(:code) { |n| "INS#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "Insumo #{n}" }
    association :category
    association :supplier
    unit { "kg" }
    current_stock { 10.5 }
    minimum_stock { 2.0 }
    purchase_price { 15.9 }
    manufacturing_date { 1.month.ago.to_date }
    expiration_date { 2.months.from_now.to_date }
    received_at { 3.weeks.ago.to_date }
    notes { "Insumo usado na produção de marmitas." }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :below_minimum_stock do
      current_stock { 1.0 }
      minimum_stock { 5.0 }
    end
  end
end
