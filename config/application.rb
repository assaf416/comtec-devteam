require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DevTeam
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # i18n
    config.i18n.available_locales = [ :en, :he ]
    config.i18n.default_locale    = :en
    config.i18n.load_path        += Dir[Rails.root.join("config", "locales", "*.yml")]

    # Time zone
    config.time_zone = "Jerusalem"
    config.active_record.default_timezone = :utc

    # Use Solid Queue for background jobs
    config.active_job.queue_adapter = :solid_queue

    # Active Storage – store documents locally
    config.active_storage.service = :local
  end
end
