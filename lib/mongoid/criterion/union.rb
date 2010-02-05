# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module Union
      # Return only the ids for the matching documents.
      #
      # Example:
      #
      # <tt>Person.where(:title => "Sir").identifiers</tt>
      #
      # Returns:
      #
      # Array of document ids.
      def identifiers
        only(:_id).execute.map(&:id)
      end

      # Perform a union of 2 criteria and return the new criteria. The first
      # pass executes both sides and merges the collections together.
      #
      # Note this operation can we extremely memory instensive for large
      # collections - use with caution.
      #
      # Example:
      #
      # <tt>criteria.or(other_criteria)</tt>
      #
      # Returns:
      #
      # A new +Criteria+.
      def or(other)
        @collection ||= execute
        @collection.concat(other.execute)
        self
      end

      alias :union :or
    end
  end
end
