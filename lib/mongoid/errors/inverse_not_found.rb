# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when no inverse_of definition can be found when needed.
    class InverseNotFound < MongoidError

      # Create then new error.
      #
      # @example Create the new error.
      #   InverseNotFound.new(Town, :citizens, Person, :town_id)
      #
      # @param [ Class ] base The base class.
      # @param [ Symbol ] name The name of the association.
      # @param [ Class ] klass The child class.
      # @param [ Symbol ] inverse The attempted inverse key.
      def initialize(base, name, klass, inverse)
        super(
          compose_message(
            "inverse_not_found",
            { base: base, name: name, klass: klass, inverse: inverse }
          )
        )
      end
    end
  end
end
