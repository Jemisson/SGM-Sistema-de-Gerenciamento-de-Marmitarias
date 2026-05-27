FactoryBot.define do
  factory :recipe do
    association :product
    sequence(:name) { |n| "Receita #{n}" }
    description { "Receita padrao do produto." }
    active { true }

    transient do
      items_count { 1 }
    end

    after(:build) do |recipe, evaluator|
      next if recipe.recipe_items.any?

      evaluator.items_count.times do
        recipe.recipe_items << build(:recipe_item, recipe: recipe)
      end
    end

    trait :inactive do
      active { false }
    end
  end
end
