# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    # Mixin for common functionality for all persistence commands.
    module Command
      attr_reader :collection, :document, :options, :validate
      # Initialize the persistence +Command+.
      #
      # Options:
      #
      # document: The +Document+ to be persisted.
      # validate: Is the document to be validated.
      def init(document, validate)
        @collection = document.embedded ? document._root.collection : document.collection
        @document = document
        @validate = validate
      end
    end
  end
end
