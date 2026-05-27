FactoryBot.define do
  factory :cash_session do
    association :opened_by, factory: [:user, :cashier]
    closed_by { nil }
    opening_amount { 100.00 }
    closing_amount { nil }
    expected_amount { nil }
    difference_amount { nil }
    opened_at { Time.current }
    closed_at { nil }
    status { :opened }
    notes { "Caixa da operacao diaria." }

    trait :closed do
      association :closed_by, factory: [:user, :manager]
      closing_amount { 120.00 }
      expected_amount { 115.00 }
      difference_amount { 5.00 }
      closed_at { opened_at + 8.hours }
      status { :closed }
    end
  end
end
