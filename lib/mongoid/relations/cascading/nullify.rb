# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Nullify

        attr_accessor :document, :relation, :metadata

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
          @document, @metadata = document, metadata
          @relation = document.send(metadata.name)
        end

        # This cascade does not delete the referenced relations, but instead
        # sets the foreign key values to nil.
        #
        # @example Nullify the reference.
        #   strategy.cascade
        def cascade
          relation.nullify if relation
        end
      end
    end
  end
end
