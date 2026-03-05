# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # This error is raised when a session is attempted to be used with a model whose client cannot use it since
    # the mongodb deployment doesn't support sessions.
    class SessionsNotSupported < MongoidError

      # Create the error.
      def initialize
        super('sessions_not_supported')
      end
    end
  end
end
