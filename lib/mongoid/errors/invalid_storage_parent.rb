# encoding: utf-8
module Mongoid
  module Errors

    # Raised when calling store_in in a sub-class of Mongoid::Document
    class InvalidStorageParent < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #    InvalidStorageParent.new(Person)
      #
      # @param [ Class ] klass The model class.
      #
      # @since 4.0.0
      def initialize(klass)
        super(
          compose_message(
            "invalid_storage_parent",
            { klass: klass }
          )
        )
      end
    end
  end
end
