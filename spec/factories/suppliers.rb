FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Fornecedor #{n}" }
    sequence(:cnpj) { |n| format("%014d", n) }
    phone { "44999999999" }
    sequence(:email) { |n| "fornecedor#{n}@sgm.test" }
    street { "Avenida Colombo" }
    number { "5790" }
    neighborhood { "Zona 7" }
    city { "Maringa" }
    state { "PR" }
    zip_code { "87020900" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
