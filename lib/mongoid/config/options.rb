# frozen_string_literal: true
# rubocop:todo all

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
      # @option options [ Proc | nil ] :on_change The callback to invoke when the
      #   setter is invoked.
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
            options[:on_change]&.call(value)
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
        # do this via the setter for each option, so that any defined on_change
        # handlers can be invoked.
        defaults.each do |setting, default|
          send(:"#{setting}=", default)
        end
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
            # JRuby String#constantize does not work here.
            level = Logger.const_get(level.upcase.to_s)
          end
          level
        end
      end
    end
  end
end
