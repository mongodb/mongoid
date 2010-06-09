require "rails"
module Rails #:nodoc:
  module Mongoid #:nodoc:
    class Railtie < Rails::Railtie #:nodoc:

      # do we want a custom log subscriber for mongoid?
      # log_subscriber :mongoid, ::Mongoid::Railties::LogSubscriber.new

      config.generators.orm :mongoid, :migration => false

      rake_tasks do
        load "mongoid/railties/database.rake"
      end

      # Initialize Mongoid. This will look for a mongoid.yml in the config
      # directory and configure mongoid appropriately.
      #
      # Example mongoid.yml:
      #
      #   defaults: &defaults
      #     host: localhost
      #     slaves:
      #       # - host: localhost
      #         # port: 27018
      #       # - host: localhost
      #         # port: 27019
      #     allow_dynamic_fields: false
      #     parameterize_keys: false
      #     persist_in_safe_mode: false
      #
      #   development:
      #     <<: *defaults
      #     database: mongoid
      initializer "setup database" do
        config_file = Rails.root.join("config", "mongoid.yml")
        if config_file.file?
          settings = YAML.load(ERB.new(config_file.read).result)[Rails.env]
          ::Mongoid.from_hash(settings) if settings.present?
        end
      end

      initializer "verify that mongoid is configured" do
        config.after_initialize do
          begin
            ::Mongoid.master
          rescue ::Mongoid::Errors::InvalidDatabase => e
            unless Rails.root.join("config", "mongoid.yml").file?
              puts "\nMongoid config not found. Create a config file at: config/mongoid.yml"
              puts "to generate one run: script/rails generate mongoid:config\n\n"
            end
          end
        end
      end
    end
  end
end