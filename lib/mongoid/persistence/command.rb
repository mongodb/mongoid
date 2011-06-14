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
        :suppress,
        :validate

      # Initialize the persistence +Command+.
      #
      # @example Delete all documents.
      #   DeleteAll.new(Person, { :validate => true }, {})
      #
      # @param [ Document, Class ] document_or_class Where to get the
      #   collection.
      # @param [ Hash ] options The options to pass to the db.
      # @param [ Hash ] selector Optional selector to use in query.
      def initialize(document_or_class, options = {}, selector = {})
        init(document_or_class)
        validate = options[:validate]
        @suppress = options[:suppress]
        @validate = (validate.nil? ? true : validate)
        @selector = selector
        @options = { :safe => safe_mode?(options) }
      end

      private

      # Setup the proper instance variables based on if the supplied argument
      # was a document object or a class object.
      #
      # @example Init the command.
      #   command.init(document_or_class)
      #
      # @param [ Document, Class ] document_or_class A document or a class.
      def init(document_or_class)
        if document_or_class.is_a?(Mongoid::Document)
          @document = document_or_class
          @collection = @document.embedded? ? @document._root.collection : @document.collection
        else
          @klass = document_or_class
          @collection = @klass.collection
        end
      end

      # Should we suppress parent notifications?
      #
      # @example Suppress notifications?
      #   command.suppress?
      #
      # @return [ true, false ] Should the parent notifcations be suppressed.
      def suppress?
        !!@suppress
      end
    end
  end
end
