# frozen_string_literal: true

require "rails"
require "rails/mongoid"

module Rails
  module Mongoid

    # Hooks Mongoid into Rails 3 and higher.
    class Railtie < Rails::Railtie

      # Mapping of rescued exceptions to HTTP responses
      #
      # @example
      #   railtie.rescue_responses
      #
      # @ return [Hash] rescued responses
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
      #       config.mongoid.logger = Logger.new(STDERR, :warn)
      #     end
      #   end
      config.mongoid = ::Mongoid::Config

      # Initialize Mongoid. This will look for a mongoid.yml in the config
      # directory and configure mongoid appropriately.
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
      initializer "mongoid.preload-models" do |app|
        config.to_prepare do
          ::Rails::Mongoid.preload_models(app)
        end
      end

      # Rails runs all initializers first before getting into any generator
      # code, so we have no way in the intitializer to know if we are
      # generating a mongoid.yml. So instead of failing, we catch all the
      # errors and print them out.
      def handle_configuration_error(e)
        puts "There is a configuration error with the current mongoid.yml."
        puts e.message
      end

      # Include Controller extension that measures Mongoid runtime
      # during request processing. The value then appears in Rails'
      # instrumentation event `process_action.action_controller`.
      #
      # The measurement is made via internal Mongo monitoring subscription
      initializer "mongoid.runtime-metric" do
        require "mongoid/railties/controller_runtime"

        ActiveSupport.on_load :action_controller do
          include ::Mongoid::Railties::ControllerRuntime::ControllerExtension
        end

        Mongo::Monitoring::Global.subscribe Mongo::Monitoring::COMMAND,
            ::Mongoid::Railties::ControllerRuntime::Collector.new
      end

    end
  end
end
