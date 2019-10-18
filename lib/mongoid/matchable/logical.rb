# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Matchable

    # Contains all the default behavior for checking for matching documents
    # given MongoDB logical operators ($and, $or, $nor and $not).
    class Logical

      attr_accessor :document

      # Logical matchers are constructed with the full document being matched.
      #
      # This is unlike other matchers which are constructed with the
      # value of the particular field (attribute) that they apply to.
      #
      # @param [ Document ] document The document to check against.
      #
      # @since 7.1.0
      def initialize(document)
        unless document.is_a?(Document)
        #byebug
          #raise TypeError, "Argument must be a Document instance: #{document}"
        end
        @document = document
      end
    end
  end
end
