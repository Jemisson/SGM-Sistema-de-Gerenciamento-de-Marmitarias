FactoryBot.define do
  factory :stock_movement do
    association :ingredient
    association :user
    movement_type { :entry }
    quantity { 5.0 }
    unit_cost { 12.5 }
    reason { "Compra de insumo" }
    occurred_at { Time.current }

    trait :exit do
      movement_type { :exit }
      unit_cost { nil }
      reason { "Uso manual de estoque" }
    end

    trait :adjustment do
      movement_type { :adjustment }
      unit_cost { nil }
      reason { "Contagem física" }
    end
  end
end
