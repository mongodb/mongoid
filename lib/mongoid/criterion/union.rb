# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Union
      # Perform a union of 2 criteria and return the new criteria. The first
      # pass executes both sides and merges the collections together.
      #
      # Example:
      #
      # <tt>criteria.or(other_criteria)</tt>
      def or(other)
        @collection ||= (execute + other.execute); self
      end

      alias :union :or
    end
  end
end
