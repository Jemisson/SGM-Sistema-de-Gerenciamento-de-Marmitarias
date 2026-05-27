FactoryBot.define do
  factory :cash_movement do
    association :cash_session
    association :user, factory: [:user, :cashier]
    movement_type { :income }
    amount { 10.00 }
    description { "Movimentacao manual de caixa." }
    source_type { nil }
    source_id { nil }
    occurred_at { Time.current }

    trait :expense do
      movement_type { :expense }
    end

    trait :opening do
      movement_type { :opening }
      description { "Abertura de caixa" }
    end

    trait :closing do
      movement_type { :closing }
      description { "Fechamento de caixa" }
    end
  end
end
