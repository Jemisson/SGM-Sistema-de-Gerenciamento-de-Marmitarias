FactoryBot.define do
  factory :audit_log do
    association :user
    action { "auth.login" }
    auditable { user }
    ip_address { "127.0.0.1" }
    user_agent { "RSpec" }
    metadata { { "source" => "spec" } }
    occurred_at { Time.current }
  end
end
