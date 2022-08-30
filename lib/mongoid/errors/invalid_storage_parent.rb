# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when calling store_in in a sub-class of Mongoid::Document
    #
    # @deprecated
    class InvalidStorageParent < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #    InvalidStorageParent.new(Person)
      #
      # @param [ Class ] klass The model class.
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
