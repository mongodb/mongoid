# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a bad configuration option is attempted to be
    # set.
    class InvalidConfigOption < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidConfigOption.new(:name, [ :option ])
      #
      # @param [ Symbol | String ] name The attempted config option name.
      def initialize(name)
        super(
          compose_message(
            "invalid_config_option",
            { name: name, options: Config.settings.keys.map(&:inspect).join(", ") }
          )
        )
      end
    end
  end
end
