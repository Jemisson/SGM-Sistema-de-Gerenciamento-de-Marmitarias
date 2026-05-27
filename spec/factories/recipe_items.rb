FactoryBot.define do
  factory :recipe_item do
    association :recipe
    association :ingredient
    quantity { 0.250 }
    unit { "kg" }
  end
end
