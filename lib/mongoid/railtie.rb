# encoding: utf-8
require "singleton"
require "mongoid"
require "mongoid/config"
require "mongoid/railties/document"
require "rails"
require "rails/mongoid"

module Rails #:nodoc:
  module Mongoid #:nodoc:
    class Railtie < Rails::Railtie #:nodoc:

      # Determine which generator to use. app_generators was introduced after
      # 3.0.0.
      #
      # @example Get the generators method.
      #   railtie.generators
      #
      # @return [ Symbol ] The method name to use.
      #
      # @since 2.0.0.rc.4
      def self.generator
        config.respond_to?(:app_generators) ? :app_generators : :generators
      end

      config.send(generator).orm :mongoid, :migration => false

      rake_tasks do
        load "mongoid/railties/database.rake"
      end

      # Exposes Mongoid's configuration to the Rails application configuration.
      #
      # @example Set up configuration in the Rails app.
      #   module MyApplication
      #     class Application < Rails::Application
      #       config.mongoid.logger = Logger.new($stdout, :warn)
      #       config.mongoid.reconnect_time = 10
      #     end
      #   end
      config.mongoid = ::Mongoid::Config

      # Initialize Mongoid. This will look for a mongoid.yml in the config
      # directory and configure mongoid appropriately.
      #
      # @example mongoid.yml
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

      # After initialization we will warn the user if we can't find a mongoid.yml and
      # alert to create one.
      initializer "warn when configuration is missing" do
        config.after_initialize do
          unless Rails.root.join("config", "mongoid.yml").file?
            puts "\nMongoid config not found. Create a config file at: config/mongoid.yml"
            puts "to generate one run: rails generate mongoid:config\n\n"
          end
        end
      end

      # Due to all models not getting loaded and messing up inheritance queries
      # and indexing, we need to preload the models in order to address this.
      #
      # This will happen every request in development, once in ther other
      # environments.
      initializer "preload all application models" do |app|
        config.to_prepare do
          ::Rails::Mongoid.load_models(app) unless $rails_rake_task
        end
      end

      # Set the proper error types for Rails. DocumentNotFound errors should be
      # 404s and not 500s, validation errors are 422s.
      initializer "load http errors" do |app|
        config.after_initialize do
          ActionDispatch::ShowExceptions.rescue_responses.update({
            "Mongoid::Errors::DocumentNotFound" => :not_found,
            "Mongoid::Errors::Validations" => 422
          })
        end
      end

      # When workers are forked in passenger and unicorn, we need to reconnect
      # to the database to all the workers do not share the same connection.
      initializer "reconnect to master if application is preloaded" do
        config.after_initialize do

          # Unicorn clears the START_CTX when a worker is forked, so if we have
          # data in START_CTX then we know we're being preloaded. Unicorn does
          # not provide application-level hooks for executing code after the
          # process has forked, so we reconnect lazily.
          if defined?(Unicorn) && !Unicorn::HttpServer::START_CTX.empty?
            ::Mongoid.reconnect!(false)
          end

          # Passenger provides the :starting_worker_process event for executing
          # code after it has forked, so we use that and reconnect immediately.
          if defined?(PhusionPassenger)
            PhusionPassenger.on_event(:starting_worker_process) do |forked|
              if forked
                ::Mongoid.reconnect!
              end
            end
          end
        end
      end
    end
  end
end
