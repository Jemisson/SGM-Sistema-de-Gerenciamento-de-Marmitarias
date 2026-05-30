# frozen_string_literal: true

require "active_support/core_ext/integer/time"
Rails.application.routes.default_url_options[:host] =
  ENV.fetch("DEFAULT_URL_HOST", "https://apisgm.jemison.dev.br")

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.active_storage.service = :staging_disk
  config.force_ssl = true

  config.logger = ActiveSupport::Logger.new(STDOUT) # rubocop:disable Style/GlobalStdStream
                                       .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_level = :debug
  config.log_tags = [:request_id]
  config.action_mailer.perform_caching = false
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
