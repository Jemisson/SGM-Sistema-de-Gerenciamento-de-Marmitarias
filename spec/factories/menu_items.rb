FactoryBot.define do
  factory :menu_item do
    association :menu
    association :product
    available { true }
    price_override { 19.90 }
  end
end
