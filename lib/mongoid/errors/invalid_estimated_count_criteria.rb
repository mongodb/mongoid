# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when trying to call estimated_count
    # on a filtered criteria.
    class InvalidEstimatedCountCriteria < MongoidError

      # Creates the exception.
      #
      # @param [ String ] class_name The name of the criteria
      #   class used to call estimated count.
      #
      # @api private
      def initialize(class_name)
        super(
          compose_message(
            "invalid_estimated_count_criteria",
            { class_name: class_name }
          )
        )
      end
    end
  end
end
