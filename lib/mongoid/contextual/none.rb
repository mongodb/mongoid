# encoding: utf-8
module Mongoid
  module Contextual
    class None
      include Enumerable
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
      #
      # @since 4.0.0
      def ==(other)
        other.is_a?(None)
      end

      # Iterate over the null context. There are no documents to iterate over
      # in this case.
      #
      # @example Iterate over the context.
      #   context.each do |doc|
      #     puts doc.name
      #   end
      #
      # @return [ Enumerator ] The enumerator.
      #
      # @since 4.0.0
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
      # @example Do any documents exist for the context.
      #   context.exists?
      #
      # @return [ true, false ] If the count is more than zero.
      #
      # @since 4.0.0
      def exists?; false; end


      # Allow pluck for null context.
      #
      # @example Allow pluck for null context.
      #   context.pluck(:name)
      #
      # @param [ String, Symbol, Array ] field or fields to pluck.
      #
      # @return [ Array ] Emtpy Array
      def pluck(*args)
        []
      end

      # Create the new null context.
      #
      # @example Create the new context.
      #   Null.new(criteria)
      #
      # @param [ Criteria ] The criteria.
      #
      # @since 4.0.0
      def initialize(criteria)
        @criteria, @klass = criteria, criteria.klass
      end

      # Always returns nil.
      #
      # @example Get the last document.
      #   context.last
      #
      # @return [ nil ] Always nil.
      #
      # @since 4.0.0
      def last; nil; end

      # Always returns zero.
      #
      # @example Get the length of matching documents.
      #   context.length
      #
      # @return [ Integer ] Always zero.
      #
      # @since 4.0.0
      def length
        entries.length
      end
      alias :size :length
    end
  end
end
