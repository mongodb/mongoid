# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cascading #:nodoc:
      class Strategy

        attr_accessor :relation, :metadata

        # Initialize the new cascade strategy, which will set up the relation
        # and the metadata.
        #
        # @example Instantiate the strategy
        #   Strategy.new(document, metadata)
        #
        # @param [ Document ] document The document to cascade from.
        # @param [ Metadata ] metadata The relation's metadata.
        #
        # @return [ Strategy ] The new strategy.
        def initialize(document, metadata)
          @relation, @metadata = document.send(metadata.name), metadata
        end
      end
    end
  end
end
