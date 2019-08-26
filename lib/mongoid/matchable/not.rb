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
        if document.is_a?(Document)
          document._matches?(condition.first[0] => condition.first[1])
        else
          !recursive_matches?(document, condition.first[0], condition.first[1])
        end
      end
    end
  end
end
