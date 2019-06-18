# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when invalid options are passed to an association macro.
    class InvalidOptions < MongoidError

      # Instantiate the options error.
      #
      # @example Create the error.
      #   InvalidOptions.new(:name, :polymorphic, [ :as ])
      #
      # @param [ Symbol ] name The name of the association.
      # @param [ Symbol ] invalid The invalid option.
      # @param [ Array<Symbol> ] valid The allowed options.
      #
      # @since 2.1.0
      def initialize(name, invalid, valid)
        super(
          compose_message(
            "invalid_options",
            { name: name, invalid: invalid, valid: valid.join(', ') }
          )
        )
      end
    end
  end
end
