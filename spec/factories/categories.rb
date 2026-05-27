FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Categoria #{n}" }
    description { "Categoria usada para classificar insumos e produtos." }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
