# encoding: utf-8
require "mongoid/railties/document"
require "rails"
require "rails/mongoid"

module Rails
  module Mongoid

    # Hooks Mongoid into Rails 3 and higher.
    #
    # @since 2.0.0
    class Railtie < Rails::Railtie

      # Mapping of rescued exceptions to HTTP responses
      #
      # @example
      #   railtie.rescue_responses
      #
      # @ return [Hash] rescued responses
      #
      # @since 2.4.3
      def self.rescue_responses
        {
          "Mongoid::Errors::DocumentNotFound" => :not_found,
          "Mongoid::Errors::Validations" => 422
        }
      end

      config.app_generators.orm :mongoid, migration: false

      if config.action_dispatch.rescue_responses
        config.action_dispatch.rescue_responses.merge!(rescue_responses)
      end

      rake_tasks do
        load "mongoid/railties/database.rake"
      end

      # Exposes Mongoid's configuration to the Rails application configuration.
      #
      # @example Set up configuration in the Rails app.
      #   module MyApplication
      #     class Application < Rails::Application
      #       config.mongoid.logger = Logger.new($stdout, :warn)
      #     end
      #   end
      #
      # @since 2.0.0
      config.mongoid = ::Mongoid::Config

      # Initialize Mongoid. This will look for a mongoid.yml in the config
      # directory and configure mongoid appropriately.
      #
      # @since 2.0.0
      initializer "mongoid.load-config" do
        config_file = Rails.root.join("config", "mongoid.yml")
        if config_file.file?
          begin
            ::Mongoid.load!(config_file)
          rescue ::Mongoid::Errors::NoClientsConfig => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoDefaultClient => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoClientDatabase => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoClientHosts => e
            handle_configuration_error(e)
          end
        end
      end

      # Set the proper error types for Rails. DocumentNotFound errors should be
      # 404s and not 500s, validation errors are 422s.
      #
      # @since 2.0.0
      config.after_initialize do
        unless config.action_dispatch.rescue_responses
          ActionDispatch::ShowExceptions.rescue_responses.update(Railtie.rescue_responses)
        end
        Mongo::Logger.logger = ::Mongoid.logger
      end

      # Due to all models not getting loaded and messing up inheritance queries
      # and indexing, we need to preload the models in order to address this.
      #
      # This will happen for every request in development, once in other
      # environments.
      #
      # @since 2.0.0
      initializer "mongoid.preload-models" do |app|
        config.to_prepare do
          ::Rails::Mongoid.preload_models(app)
        end
      end

      # Rails runs all initializers first before getting into any generator
      # code, so we have no way in the intitializer to know if we are
      # generating a mongoid.yml. So instead of failing, we catch all the
      # errors and print them out.
      #
      # @since 3.0.0
      def handle_configuration_error(e)
        puts "There is a configuration error with the current mongoid.yml."
        puts e.message
      end
    end
  end
end
