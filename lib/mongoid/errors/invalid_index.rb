# encoding: utf-8
module Mongoid
  module Errors

    # Raised when an invalid index is defined.
    class InvalidIndex < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidIndex.new(Band, name: 1)
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash ] spec The invalid specification.
      # @param [ Hash ] options The invalid options.
      #
      # @since 3.0.0
      def initialize(klass, spec, options)
        super(
          compose_message(
            "invalid_index",
            { klass: klass.name, spec: spec, options: options }
          )
        )
      end
    end
  end
end
