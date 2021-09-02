# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when invalid options are used to create a persistence context.
    class InvalidPersistenceOption < MongoidError

      # Instantiate the persistence context option error.
      #
      # @example Create the error.
      #   InvalidPersistenceOption.new(:invalid_option, [ :connect_timeout, :database ])
      #
      # @param [ Symbol ] invalid The invalid option.
      # @param [ Array<Symbol> ] valid The allowed options.
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
