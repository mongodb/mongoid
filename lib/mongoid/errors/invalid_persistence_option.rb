# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when invalid options are used to create a persistence context.
    #
    # @since 6.0.0
    class InvalidPersistenceOption < MongoidError

      # Instantiate the persistence context option error.
      #
      # @example Create the error.
      #   InvalidPersistenceOption.new(:invalid_option, [ :connect_timeout, :database ])
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
