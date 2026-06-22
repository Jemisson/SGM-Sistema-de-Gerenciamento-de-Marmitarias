source "https://rubygems.org"

gem "rails", "~> 8.1.3"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"
gem "devise"
gem "devise-jwt"
gem "kaminari"
gem "pundit"
gem "rswag-api"
gem "rswag-ui"

group :development, :test, :staging do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "faker"
  gem "mina", "0.3.8"
  gem "rspec-rails"
  gem "rswag-specs"
  gem "simplecov", require: false
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
