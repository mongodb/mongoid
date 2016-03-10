# encoding: utf-8
module Mongoid
  module Errors

    # Raised when invalid options are passed to a relation macro.
    class InvalidPersistenceOption < MongoidError

      # Instantiate the persistence option error.
      #
      # @example Create the error.
      #   InvalidPersistenceOptions.new(:invalid_options, [ :connect_timeout, :database ])
      #
      # @param [ Symbol ] invalid The invalid option.
      # @param [ Array<Symbol> ] valid The allowed options.
      #
      # @since 6.0.0
      def initialize(invalid, valid)
        super(
            compose_message(
                "invalid_persistence_option",
                { invalid: invalid, valid: valid }
            )
        )
      end
    end
  end
end
