# frozen_string_literal: true

require "mongoid/contextual/aggregable/none"

module Mongoid
  module Contextual
    class None
      include Enumerable
      include Aggregable::None
      include Queryable

      attr_reader :criteria, :klass

      # Check if the context is equal to the other object.
      #
      # @example Check equality.
      #   context == []
      #
      # @param [ Array ] other The other array.
      #
      # @return [ true, false ] If the objects are equal.
      def ==(other)
        other.is_a?(None)
      end

      # Get the distinct field values in null context.
      #
      # @example Get the distinct values in null context.
      #   context.distinct(:name)
      #
      # @param [ String, Symbol ] _field The name of the field.
      #
      # @return [ Array ] An empty Array.
      def distinct(_field)
        []
      end

      # Iterate over the null context. There are no documents to iterate over
      # in this case.
      #
      # @example Iterate over the null context.
      #   context.each do |doc|
      #     puts doc.name
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      def each
        if block_given?
          [].each { |doc| yield(doc) }
          self
        else
          to_enum
        end
      end

      # Do any documents exist for the context.
      #
      # @example Do any documents exist in the null context.
      #   context.exists?
      #
      # @return [ false ] Always false.
      def exists?; false; end

      # Pluck the field values in null context.
      #
      # @example Get the values for null context.
      #   context.pluck(:name)
      #
      # @param [ String, Symbol, Array ] args Field or fields to pluck.
      #
      # @return [ Array ] An empty Array.
      def pluck(*args)
        []
      end

      # Create the new null context.
      #
      # @example Create the new context.
      #   Null.new(criteria)
      #
      # @param [ Criteria ] criteria The criteria.
      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
      end

      # Always returns nil.
      #
      # @example Get the last document in null context.
      #   context.last
      #
      # @return [ nil ] Always nil.
      def last; nil; end

      # Always returns zero.
      #
      # @example Get the length of null context.
      #   context.length
      #
      # @return [ Integer ] Always zero.
      def length
        0
      end
      alias :size :length

      alias :find_first :first
      alias :one :first
    end
  end
end
