FactoryBot.define do
  factory :financial_entry do
    cash_session { nil }
    association :user, factory: [:user, :manager]
    entry_type { :income }
    category { "Outras receitas" }
    description { "Lancamento financeiro manual." }
    amount { 50.00 }
    payment_method { :pix }
    source_type { nil }
    source_id { nil }
    occurred_at { Time.current }
    active { true }

    trait :expense do
      entry_type { :expense }
      category { "Despesas operacionais" }
      description { "Pagamento de despesa." }
      amount { 20.00 }
      payment_method { :cash }
    end

    trait :inactive do
      active { false }
    end

    trait :from_sale do
      association :source, factory: :sale
      entry_type { :income }
      category { "Venda" }
    end
  end
end
