# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to instantiate a model object from the value in
    # the '_type' field of a document and the class doesn't exist.
    class UnknownModel < MongoidError

      # Create the new error.
      #
      # @example Instantiate the error.
      #   UnknownModel.new('InvalidClass', "invalid_class")
      #
      # @param [ String ] klass The model class.
      # @param [ String ] value The value used to determine the (invalid) class.
      def initialize(klass, value)
        super(
            compose_message("unknown_model", { klass: klass, value: value })
        )
      end
    end
  end
end
