# frozen_string_literal: true

require "mongoid/contextual/aggregable/none"

module Mongoid
  module Contextual
    class None
      include Enumerable
      alias :old_sum :sum

      include Aggregable::None
      include Queryable

      attr_reader :criteria, :klass

      alias :new_sum :sum

      # Get the sum in the null context.
      #
      # @example Get the sum of null context.
      #     context.sum(_field)
      #
      # @param [ Symbol ] _field The field to sum.
      #
      # @return [ Integer | Symbol ] If Mongoid.broken_aggregables is
      #   set to false, this will always be zero. Otherwise, it will return the
      #   field name as a symbol.
      def sum(_field = nil)
        if Mongoid.broken_aggregables
          old_sum(_field)
        else
          new_sum(_field)
        end
      end

      # Check if the context is equal to the other object.
      #
      # @example Check equality.
      #   context == []
      #
      # @param [ Array ] other The other array.
      #
      # @return [ true | false ] If the objects are equal.
      def ==(other)
        other.is_a?(None)
      end

      # Get the distinct field values in null context.
      #
      # @example Get the distinct values in null context.
      #   context.distinct(:name)
      #
      # @param [ String | Symbol ] _field The name of the field.
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
      # @param [ String | Symbol ] *_fields Field(s) to pluck.
      #
      # @return [ Array ] An empty Array.
      def pluck(*_fields)
        []
      end

      # Pick the field values in null context.
      #
      # @example Get the value for null context.
      #   context.pick(:name)
      #
      # @param [ String | Symbol ] *_fields Field or fields to pick.
      #
      # @return [ nil ] Always reeturn nil.
      def pick(*_fields)
        nil
      end

      # Tally the field values in null context.
      #
      # @example Get the values for null context.
      #   context.tally(:name)
      #
      # @param [ String | Symbol ] _field Field to tally.
      #
      # @return [ Hash ] An empty Hash.
      def tally(_field)
        {}
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
      # @example Get the first document in null context.
      #   context.first
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ nil ] Always nil.
      def first(limit = nil)
        [] unless limit.nil?
      end

      # Always returns nil.
      #
      # @example Get the last document in null context.
      #   context.last
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ nil ] Always nil.
      def last(limit = nil)
        [] unless limit.nil?
      end

      # Returns nil or empty array.
      #
      # @example Take a document in null context.
      #   context.take
      #
      # @param [ Integer | nil ] limit The number of documents to take or nil.
      #
      # @return [ [] | nil ] Empty array or nil.
      def take(limit = nil)
        limit ? [] : nil
      end

      # Always raises an error.
      #
      # @example Take a document in null context.
      #   context.take!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def take!
        raise Errors::DocumentNotFound.new(klass, nil, nil)
      end

      # Always returns zero.
      #
      # @example Get the length of null context.
      #   context.length
      #
      # @return [ Integer ] Always zero.
      def length
        Mongoid.broken_aggregables ? 0 : entries.length
      end
      alias :size :length

      alias :find_first :first
      alias :one :first
    end
  end
end
