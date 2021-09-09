# frozen_string_literal: true

module Mongoid
  module Errors

    # Used when attempting to get embedded paths with incorrect root path set.
    class InvalidPath < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidPath.new(Address)
      #
      # @param [ Class ] klass The document class.
      def initialize(klass)
        super(compose_message("invalid_path", { klass: klass }))
      end
    end
  end
end
