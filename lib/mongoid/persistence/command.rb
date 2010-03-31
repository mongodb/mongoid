# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Persistence commands extend from this class to get basic functionality on
    # initialization.
    class Command
      attr_reader :collection, :document, :options, :validate
      # Initialize the persistence +Command+.
      #
      # Options:
      #
      # document: The +Document+ to be persisted.
      # validate: Is the document to be validated.
      def initialize(document, validate = true)
        @collection = document.embedded ? document._root.collection : document.collection
        @document = document
        @validate = validate
        @options = { :safe => Mongoid.persist_in_safe_mode }
      end
    end
  end
end
