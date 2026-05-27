FactoryBot.define do
  factory :product do
    sequence(:code) { |n| "PROD#{n.to_s.rjust(3, '0')}" }
    sequence(:name) { |n| "Marmita #{n}" }
    description { "Produto vendido pela marmitaria." }
    association :category
    sale_price { 24.90 }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
