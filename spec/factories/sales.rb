FactoryBot.define do
  factory :sale do
    association :cash_session
    association :user, factory: [:user, :cashier]
    total_amount { 24.90 }
    payment_method { :cash }
    status { :confirmed }
    sold_at { Time.current }

    transient do
      items_count { 1 }
    end

    after(:build) do |sale, evaluator|
      next if sale.sale_items.any?

      evaluator.items_count.times do
        sale.sale_items << build(:sale_item, sale: sale)
      end
    end

    trait :canceled do
      status { :canceled }
    end
  end
end
