# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Creates the exception raised when trying to call estimated_count
    # on a filtered criteria.
    #
    # @param [ String ] class_name The class name.
    #
    # @api private
    class InvalidEstimatedCountCriteria < MongoidError
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
