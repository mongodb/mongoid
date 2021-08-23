# frozen_string_literal: true

module Mongoid
  module Config

    # Encapsulates logic for setting options.
    module Options

      # Get the defaults or initialize a new empty hash.
      #
      # @example Get the defaults.
      #   options.defaults
      #
      # @return [ Hash ] The default options.
      def defaults
        @defaults ||= {}
      end

      # Define a configuration option with a default.
      #
      # @example Define the option.
      #   Options.option(:logger, :default => Logger.new(STDERR, :warn))
      #
      # @param [ Symbol ] name The name of the configuration option.
      # @param [ Hash ] options Extras for the option.
      #
      # @option options [ Object ] :default The default value.
      def option(name, options = {})
        defaults[name] = settings[name] = options[:default]

        class_eval do
          # log_level accessor is defined specially below
          unless name.to_sym == :log_level
            define_method(name) do
              settings[name]
            end
          end

          define_method("#{name}=") do |value|
            settings[name] = value
          end

          define_method("#{name}?") do
            !!send(name)
          end
        end
      end

      # Reset the configuration options to the defaults.
      #
      # @example Reset the configuration options.
      #   config.reset
      #
      # @return [ Hash ] The defaults.
      def reset
        settings.replace(defaults)
      end

      # Get the settings or initialize a new empty hash.
      #
      # @example Get the settings.
      #   options.settings
      #
      # @return [ Hash ] The setting options.
      def settings
        @settings ||= {}
      end

      # Get the log level.
      #
      # @example Get the log level.
      #   config.log_level
      #
      # @return [ Integer ] The log level.
      def log_level
        if level = settings[:log_level]
          unless level.is_a?(Integer)
            level = level.upcase.to_s
            level = "Logger::#{level}".constantize
          end
          level
        end
      end
    end
  end
end
