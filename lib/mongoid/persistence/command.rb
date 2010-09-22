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
        if document_or_class.is_a?(Mongoid::Document)
          @document = document_or_class
          @collection = @document.embedded? ? @document._root.collection : @document.collection
        else
          @klass = document_or_class
          @collection = @klass.collection
        end
        validate = options[:validate]
        @selector = selector
        @validate = (validate.nil? ? true : validate)
        @options = { :safe => safe_mode?(options) }
      end
    end
  end
end
