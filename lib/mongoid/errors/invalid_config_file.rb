# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when a bad configuration file is attempted to be
    # loaded.
    class InvalidConfigFile < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidConfigFile.new(:name, [ :option ])
      #
      # @param [ String ] path The file path of the config.
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
