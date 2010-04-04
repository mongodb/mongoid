# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Persistence commands extend from this class to get basic functionality on
    # initialization.
    class Command
      attr_reader \
        :collection,
        :document,
        :klass,
        :options,
        :selector,
        :validate

      # Initialize the persistence +Command+.
      #
      # Options:
      #
      # document_or_class: The +Document+ or +Class+ to get the collection.
      # validate: Is the document to be validated.
      # selector: Optional selector to use in query.
      #
      # Example:
      #
      # <tt>DeleteAll.new(Person, false, {})</tt>
      def initialize(document_or_class, validate = true, selector = {})
        if document_or_class.is_a?(Mongoid::Document)
          @document = document_or_class
          @collection = @document.embedded ? @document._root.collection : @document.collection
        else
          @klass = document_or_class
          @collection = @klass.collection
        end
        @selector, @validate = selector, validate
        @options = { :safe => Mongoid.persist_in_safe_mode }
      end
    end
  end
end
