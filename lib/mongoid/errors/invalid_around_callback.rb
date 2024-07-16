# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when an around callback is
    # defined by the user without a yield
    class InvalidAroundCallback < MongoidError

      # Create the new error.
      #
      # @api private
      def initialize
        super(compose_message("invalid_around_callback"))
      end
    end
  end
end
