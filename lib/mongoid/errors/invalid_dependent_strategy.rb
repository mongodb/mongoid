# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when an invalid strategy is defined for an association dependency.
    class InvalidDependentStrategy < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidDependentStrategy.new(association, invalid_strategy, valid_strategies)
      #
      # @param [ Mongoid::Association ] association The association for which this
      #   dependency is defined.
      # @param [ Symbol, String ] invalid_strategy The attempted invalid strategy.
      # @param [ Array<Symbol> ] valid_strategies The valid strategies.
      #
      # @since 7.0.0
      def initialize(association, invalid_strategy, valid_strategies)
        super(
            compose_message(
                "invalid_dependent_strategy",
                { association: association,
                  invalid_strategy: invalid_strategy,
                  valid_strategies: valid_strategies
                }
            )
        )
      end
    end
  end
end
