# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when an invalid index is defined.
    class InvalidIndex < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidIndex.new(Band, name: 1)
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash ] spec The invalid specification.
      #
      # @since 3.0.0
      def initialize(klass, spec)
        super(
          compose_message(
            "invalid_index",
            { klass: klass.name, spec: spec }
          )
        )
      end
    end
  end
end
