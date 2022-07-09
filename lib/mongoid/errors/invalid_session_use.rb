# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when a session is attempted to be used with a model whose client cannot use it, if
    #   sessions are nested, or if the mongodb deployment doesn't support sessions.
    class InvalidSessionUse < MongoidError

      # Create the error.
      #
      # @example Create the error.
      #   InvalidSessionUse.new(:invalid_session_use)
      #
      # @param [ :invalid_session_use | :invalid_session_nesting ] error_type The type of session misuse.
      def initialize(error_type)
        super(compose_message(error_type.to_s))
      end
    end
  end
end
