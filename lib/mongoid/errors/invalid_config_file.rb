# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a bad configuration file is attempted to be
    # loaded.
    class InvalidConfigFile < MongoidError

      # Create the new error.
      #
      # @param [ String ] path The path of the config file used.
      #
      # @api private
      def initialize(path)
        super(
          compose_message(
            "invalid_config_file",
            { path: path }
          )
        )
      end
    end
  end
end
