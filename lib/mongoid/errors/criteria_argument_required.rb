# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a method on Criteria is given a nil argument.
    class CriteriaArgumentRequired < MongoidError

      # Creates the new exception instance.
      #
      # @api private
      def initialize(query_method)
        super(compose_message("criteria_argument_required",
          query_method: query_method))
      end
    end
  end
end
