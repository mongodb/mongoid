# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Scoping
      attr_accessor :unscopable

      # Is the criteria unscopable? This is here as a temporary workaround
      # until we can rewrite the entire scoping.
      #
      # @example Is the criteria unscopable?
      #   criteria.unscopable?
      #
      # @return [ true, false ] If default scoping is not allowed.
      #
      # @since 2.4.0
      def unscopable?
        !!@unscopable
      end
    end
  end
end
