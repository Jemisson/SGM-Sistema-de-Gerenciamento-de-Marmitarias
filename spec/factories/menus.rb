FactoryBot.define do
  factory :menu do
    sequence(:name) { |n| "Cardapio #{n}" }
    start_date { Date.current }
    end_date { Date.current + 7.days }
    status { :active }
    active { true }

    transient do
      items_count { 1 }
    end

    after(:build) do |menu, evaluator|
      next if menu.menu_items.any?

      evaluator.items_count.times do
        menu.menu_items << build(:menu_item, menu: menu)
      end
    end

    trait :draft do
      status { :draft }
    end

    trait :inactive_status do
      status { :inactive }
    end

    trait :disabled do
      active { false }
    end
  end
end
