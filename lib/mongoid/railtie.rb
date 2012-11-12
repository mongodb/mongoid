# encoding: utf-8
require "mongoid"
require "mongoid/config"
require "mongoid/railties/document"
require "rails"
require "rails/mongoid"

module Rails
  module Mongoid
    class Railtie < Rails::Railtie

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

      config.send(generator).orm :mongoid, migration: false

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
      #       config.mongoid.persist_in_safe_mode = true
      #     end
      #   end
      config.mongoid = ::Mongoid::Config

      # Initialize Mongoid. This will look for a mongoid.yml in the config
      # directory and configure mongoid appropriately.
      initializer "setup database" do
        config_file = Rails.root.join("config", "mongoid.yml")
        if config_file.file?
          begin
            ::Mongoid.load!(config_file)
          rescue ::Mongoid::Errors::NoSessionsConfig => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoDefaultSession => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoSessionDatabase => e
            handle_configuration_error(e)
          rescue ::Mongoid::Errors::NoSessionHosts => e
            handle_configuration_error(e)
          end
        end
      end

      # After initialization we will warn the user if we can't find a mongoid.yml and
      # alert to create one.
      initializer "warn when configuration is missing" do
        config.after_initialize do
          unless Rails.root.join("config", "mongoid.yml").file? || ::Mongoid.configured?
            puts "\nMongoid config not found. Create a config file at: config/mongoid.yml"
            puts "to generate one run: rails generate mongoid:config\n\n"
          end
        end
      end

      # Set the proper error types for Rails. DocumentNotFound errors should be
      # 404s and not 500s, validation errors are 422s.
      initializer "load http errors" do |app|
        config.after_initialize do
          unless config.action_dispatch.rescue_responses
            ActionDispatch::ShowExceptions.rescue_responses.update(Railtie.rescue_responses)
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
          if $rails_rake_task
            # We previously got rid of this, however in the case where
            # threadsafe! is enabled we must load all models so things like
            # creating indexes works properly.
            ::Rails::Mongoid.load_models(app)
          else
            ::Rails::Mongoid.preload_models(app)
          end
        end
      end

      # Need to include the Mongoid identity map middleware.
      initializer "include the identity map" do |app|
        app.config.middleware.use "Rack::Mongoid::Middleware::IdentityMap"
      end

      # Instantitate any registered observers after Rails initialization and
      # instantiate them after being reloaded in the development environment
      initializer "instantiate observers" do
        config.after_initialize do
          ::Mongoid::instantiate_observers
          ActionDispatch::Reloader.to_prepare do
            ::Mongoid.instantiate_observers
          end
        end
      end

      initializer "reconnect to master if application is preloaded" do
        config.after_initialize do
          # Unicorn clears the START_CTX when a worker is forked, so if we have
          # data in START_CTX then we know we're being preloaded. Unicorn does
          # not provide application-level hooks for executing code after the
          # process has forked, so we reconnect lazily.
          if defined?(Unicorn) && !Unicorn::HttpServer::START_CTX.empty?
            ::Mongoid.default_session.disconnect if ::Mongoid.configured?
          end

          # Passenger provides the :starting_worker_process event for executing
          # code after it has forked, so we use that and reconnect immediately.
          if ::Mongoid.running_with_passenger?
            PhusionPassenger.on_event(:starting_worker_process) do |forked|
              ::Mongoid.default_session.disconnect if forked
            end
          end
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
    end
  end
end
