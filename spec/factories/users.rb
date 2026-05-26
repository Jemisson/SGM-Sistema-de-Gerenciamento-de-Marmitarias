FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Usuario SGM #{n}" }
    birth_date { 30.years.ago.to_date }
    sequence(:cpf) { |n| format("%011d", n) }
    phone { "44999999999" }
    role { :cashier }
    gender { "not_informed" }
    marital_status { "not_informed" }
    sequence(:email) { |n| "usuario#{n}@sgm.test" }
    password { "password123" }
    active { true }
    street { "Avenida Colombo" }
    number { "5790" }
    neighborhood { "Zona 7" }
    city { "Maringa" }
    state { "PR" }
    zip_code { "87020900" }

    trait :admin do
      role { :admin }
    end

    trait :manager do
      role { :manager }
    end

    trait :cashier do
      role { :cashier }
    end

    trait :inactive do
      active { false }
    end
  end
end
