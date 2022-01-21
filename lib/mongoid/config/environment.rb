# frozen_string_literal: true

module Mongoid
  module Config

    # Encapsulates logic for getting environment information.
    module Environment
      extend self

      # Get the name of the environment that Mongoid is running under.
      #
      # Uses the following sources in order:
      # - If +::Rails+ is defined, +Rails.env+.
      # - If +::Sinatra+ is defined, +Sinatra::Base.environment+.
      # - +RACK_ENV+
      # - +MONGOID_ENV*
      #
      # @example Get the env name.
      #   Environment.env_name
      #
      # @raise [ Errors::NoEnvironment ] If environment name cannot be
      #   determined because none of the sources was set.
      #
      # @return [ String ] The name of the current environment.
      # @api public
      def env_name
        if defined?(::Rails)
          return ::Rails.env
        end
        if defined?(::Sinatra)
          return ::Sinatra::Base.environment.to_s
        end
        ENV["RACK_ENV"] || ENV["MONGOID_ENV"] or raise Errors::NoEnvironment
      end

      # Load the yaml from the provided path and return the settings for the
      # specified environment, or for the current Mongoid environment.
      #
      # @example Load the yaml.
      #   Environment.load_yaml("/work/mongoid.yml")
      #
      # @param [ String ] path The location of the file.
      # @param [ String | Symbol ] environment Optional environment name to
      #   override the current Mongoid environment.
      #
      # @return [ Hash ] The settings.
      # @api private
      def load_yaml(path, environment = nil)
        env = environment ? environment.to_s : env_name
        contents = File.new(path).read
        if contents.empty?
          raise Mongoid::Errors::EmptyConfigFile.new(path)
        end
        data = if RUBY_VERSION.start_with?("2.5")
          YAML.safe_load(ERB.new(contents).result, [Symbol], [], true)
        else
          YAML.safe_load(ERB.new(contents).result, permitted_classes: [Symbol], aliases: true)
        end
        unless data.is_a?(Hash)
          raise Mongoid::Errors::InvalidConfigFile.new(path)
        end
        data[env]
      end
    end
  end
end
