# frozen_string_literal: true

module Mongoid
  module Errors

    class InvalidEstimatedCountScoping < MongoidError

      # Creates the exception raised when trying to call estimated_count
      # on Model with a default scope
      #
      # @param [ String ] class_name The klass of the criteria used to call
      #                              estimated count.
      #
      # @api private
      def initialize(class_name)
        super(
          compose_message(
            "invalid_estimated_count_scoping",
            { class_name: class_name }
          )
        )
      end
    end
  end
end
