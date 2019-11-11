# frozen_string_literal: true
# encoding: utf-8

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
      #
      # @since 2.3.0
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
      #
      # @since 2.3.0
      # @api private
      def load_yaml(path, environment = nil)
        env = environment ? environment.to_s : env_name
        YAML.load(ERB.new(File.new(path).read).result)[env]
      end
    end
  end
end
