# encoding: utf-8
module Mongoid #:nodoc:
  module Contexts #:nodoc:
    class Enumerable
      include Paging
      attr_reader :criteria

      delegate :first, :last, :to => :execute

      # Return aggregation counts of the grouped documents. This will count by
      # the first field provided in the fields array.
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, count as values
      def aggregate
        counts = {}
        group.each_pair { |key, value| counts[key] = value.size }
        counts
      end

      # Gets the number of documents in the array. Delegates to size.
      def count
        @count ||= documents.size
      end

      # Target documents array from the criteria. Set by the association
      # macros directly onto the criteria.
      #
      # Returns:
      #
      # The target documents array from the criteria
      def documents
        @criteria.documents
      end

      # Groups the documents by the first field supplied in the field options.
      #
      # Returns:
      #
      # A +Hash+ with field values as keys, arrays of documents as values.
      def group
        field = options[:fields].first
        documents.group_by { |doc| doc.send(field) }
      end

      # Enumerable implementation of execute. Returns matching documents for
      # the selector, and adds options if supplied.
      #
      # Returns:
      #
      # An +Array+ of documents that matched the selector.
      def execute(paginating = false)
        limit(documents.select { |document| document.matches?(selector) })
      end

      # Create the new enumerable context. This will need the selector and
      # options from a +Criteria+ and a documents array that is the underlying
      # array of embedded documents from a has many association.
      #
      # Example:
      #
      # <tt>Mongoid::Contexts::Enumerable.new(criteria)</tt>
      def initialize(criteria)
        @criteria = criteria
      end

      # Get the largest value for the field in all the documents.
      #
      # Returns:
      #
      # The numerical largest value.
      def max(field)
        determine(field, :>=)
      end

      # Get the smallest value for the field in all the documents.
      #
      # Returns:
      #
      # The numerical smallest value.
      def min(field)
        determine(field, :<=)
      end

      # Get one document.
      #
      # Returns:
      #
      # The first document in the +Array+
      alias :one :first

      # Options from the criteria
      #
      # Returns:
      #
      # The options from the criteria
      def options
        criteria.options
      end

      # Selector from the criteria
      #
      # Returns:
      #
      # The selector from the criteria
      def selector
        criteria.selector
      end

      # Get the sum of the field values for all the documents.
      #
      # Returns:
      #
      # The numerical sum of all the document field values.
      def sum(field)
        sum = documents.inject(nil) do |memo, doc|
          value = doc.send(field)
          memo ? memo += value : value
        end
      end

      protected
      # If the field exists, perform the comparison and set if true.
      def determine(field, operator)
        matching = documents.inject(nil) do |memo, doc|
          value = doc.send(field)
          (memo && memo.send(operator, value)) ? memo : value
        end
      end

      # Limits the result set if skip and limit options.
      def limit(documents)
        skip, limit = options[:skip], options[:limit]
        if skip && limit
          return documents.slice(skip, limit)
        end
        documents
      end
    end
  end
end
