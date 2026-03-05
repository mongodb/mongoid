# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when a session is attempted to be used with a model whose client already
    # has an opened session.
    class InvalidSessionNesting < MongoidError

      # Create the error.
      def initialize
        super(compose_message('invalid_session_nesting'))
      end
    end
  end
end
