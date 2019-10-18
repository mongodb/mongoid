# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Performs a logical NOT operation.
    class Not < Default

      # Return true if the attribute does not match the value.
      #
      # @example Do the values not match?
      #   matcher._matches?({ :key => 10 })
      #
      # @return [ true, false ] True if the value does not match, false otherwise
      def _matches?(condition)
        !document._matches?(condition)
      end
    end
  end
end
