# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Persistence commands extend from this class to get basic functionality on
    # initialization.
    class Command
      include Mongoid::Safe

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
      # options: Options like validation or safe mode.
      # selector: Optional selector to use in query.
      #
      # Example:
      #
      # <tt>DeleteAll.new(Person, { :validate => true }, {})</tt>
      def initialize(document_or_class, options = {}, selector = {})
        init(document_or_class)
        validate = options[:validate]
        @validate = (validate.nil? ? true : validate)
        @selector = selector
        @options = { :safe => safe_mode?(options) }
      end

      private

      # Setup the proper instance variables based on if the supplied argument
      # was a document object or a class object.
      #
      # Example:
      #
      # <tt>init(document_or_class)</tt>
      #
      # Options:
      #
      # document_or_class: A document or a class.
      def init(document_or_class)
        if document_or_class.is_a?(Mongoid::Document)
          @document = document_or_class
          @collection = @document.embedded? ? @document._root.collection : @document.collection
        else
          @klass = document_or_class
          @collection = @klass.collection
        end
      end
    end
  end
end
