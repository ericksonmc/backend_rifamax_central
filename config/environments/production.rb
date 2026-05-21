# frozen_string_literal: true

require 'active_support/core_ext/integer/time'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = false

  # Enable server timing
  config.server_timing = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: 'localhost:4000' }

  config.action_mailer.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: 587,
    user_name: 'apikey',
    password: ENV['sendgrid_api_key'],
    domain: "api.rifamax.app",
    authentication: 'plain',
    enable_starttls_auto: true
  }

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  Paperclip.options[:command_path] = '/usr/local/bin/'

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  config.action_cable.allowed_request_origins = [%r{http://*}, %r{https://*}, %r{file://*}]

#  config.hosts = [
#    /.*\.rifamax\.app/,
#    /\A127\.0\.0\.1(:\d+)?\z/,
#    "dataweb.lvh.me",
#    "testcda.com",
#    "192.168.100.20", # <= Agregue la ip del webserver
#  ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
#  config.action_cable.allowed_request_origins = [
#    'https://dataweb.testcda.com',
#    'https://testcda.com',
#    'https://www.testcda.com',
#    'https://dataweb.cdapuestas.com',
#    'https://cdapuestas.com',
#    'https://www.cdapuestas.com',
#    'http://localhost:3000',
#    'http://localhost:4000',
#    'https://api.rifamax.app',
#    %r{\Ahttp://192\.168\.68\.66(:\d+)?\z},
#    %r{\Ahttp://192\.168\.100\.20(:\d+)?\z}, # <= igual aqui tambien la agregue este regex porque con eso acepto el request desde la VM webserver dedde cualquier puerto
#  ]

  # config.action_mailer.service = :local

  config.i18n.fallbacks = false

  config.log_level = :info

  config.log_tags = [:request_id]

  # Cable
  config.action_cable.url = 'ws://localhost:4000/cable'
  config.action_cable.disable_request_forgery_protection = true

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true
end
