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
      # @example Do any documents exist for given _id.
      #   context.exists?(BSON::ObjectId(...))
      #
      # @example Do any documents exist for given conditions.
      #   context.exists?(name: "...")
      #
      # @param [ Hash | Object | false ] id_or_conditions an _id to
      #   search for, a hash of conditions, nil or false.
      #
      # @return [ false ] Always false.
      def exists?(id_or_conditions = :none); false; end

      # Pluck the field values in null context.
      #
      # @example Get the values for null context.
      #   context.pluck(:name)
      #
      # @param [ [ String | Symbol ]... ] *_fields Field(s) to pluck.
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
      # @param [ [ String | Symbol ]... ] *_fields Field(s) to pick.
      #
      # @return [ nil ] Always return nil.
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
      # @return [ [] | nil ] Empty array or nil.
      def first(limit = nil)
        [] unless limit.nil?
      end

      # Always raises an error.
      #
      # @example Get the first document in null context.
      #   context.first!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def first!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the last document in null context.
      #   context.last
      #
      # @param [ Integer ] limit The number of documents to return.
      #
      # @return [ [] | nil ] Empty array or nil.
      def last(limit = nil)
        [] unless limit.nil?
      end

      # Always raises an error.
      #
      # @example Get the last document in null context.
      #   context.last!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def last!
        raise_document_not_found_error
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
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the second document in null context.
      #   context.second
      #
      # @return [ nil ] Always nil.
      def second
        nil
      end

      # Always raises an error.
      #
      # @example Get the second document in null context.
      #   context.second!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def second!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the third document in null context.
      #   context.third
      #
      # @return [ nil ] Always nil.
      def third
        nil
      end

      # Always raises an error.
      #
      # @example Get the third document in null context.
      #   context.third!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def third!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the fourth document in null context.
      #   context.fourth
      #
      # @return [ nil ] Always nil.
      def fourth
        nil
      end

      # Always raises an error.
      #
      # @example Get the fourth document in null context.
      #   context.fourth!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def fourth!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the fifth document in null context.
      #   context.fifth
      #
      # @return [ nil ] Always nil.
      def fifth
        nil
      end

      # Always raises an error.
      #
      # @example Get the fifth document in null context.
      #   context.fifth!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def fifth!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the second to last document in null context.
      #   context.second_to_last
      #
      # @return [ nil ] Always nil.
      def second_to_last
        nil
      end

      # Always raises an error.
      #
      # @example Get the second to last document in null context.
      #   context.second_to_last!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def second_to_last!
        raise_document_not_found_error
      end

      # Always returns nil.
      #
      # @example Get the third to last document in null context.
      #   context.third_to_last
      #
      # @return [ nil ] Always nil.
      def third_to_last
        nil
      end

      # Always raises an error.
      #
      # @example Get the third to last document in null context.
      #   context.third_to_last!
      #
      # @raises [ Mongoid::Errors::DocumentNotFound ] always raises.
      def third_to_last!
        raise_document_not_found_error
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

      private

      def raise_document_not_found_error
        raise Errors::DocumentNotFound.new(klass, nil, nil)
      end
    end
  end
end
