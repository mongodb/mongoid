# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # Raised when something other than a hash is passed as an argument
    # to $not.
    class NotRequiresHash < InvalidFind

      # Create the new exception.
      #
      # @since 7.1.0
      def initialize(msg = nil)
        msg ||= compose_message("not_requires_hash", {})
        super(msg)
      end
    end
  end
end
