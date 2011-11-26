# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when trying to load configuration with no RACK_ENV set
    class NoEnvironment < MongoidError

      # Create the new no environment error.
      #
      # @example Create the new no environment error.
      #   NoEnvironment.new
      #
      # @since 2.4.0
      def initialize
        super(translate("no_environment", {}))
      end
    end
  end
end
