# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Errors

    # Used when trying to persist data when metadata has not been set.
    class NoMetadata < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   NoMetadata.new(Address)
      #
      # @param [ Class ] klass The document class.
      def initialize(klass)
        super(compose_message("no_metadata", { klass: klass }))
      end
    end
  end
end
