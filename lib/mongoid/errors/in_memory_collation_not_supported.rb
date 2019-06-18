# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when attempting to do a query with a
    # collation on documents in memory.
    class InMemoryCollationNotSupported < MongoidError

      # Create the new error.
      #
      # @example Create the new unsupported collation error.
      #   InMemoryCollationNotSupported.new
      #
      # @since 6.1.0
      def initialize
        super(compose_message("in_memory_collation_not_supported"))
      end
    end
  end
end
