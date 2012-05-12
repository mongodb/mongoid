# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Delete

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

        # Execute the cascading deletion for the relation if it already exists.
        # This should be optimized in the future potentially not to load all
        # objects from the db.
        #
        # @example Perform the cascading delete.
        #   strategy.cascade
        #
        # @since 2.0.0
        def cascade
          if relation
            if relation.cascades.empty?
              relation.clear
            else
              ::Array.wrap(relation).each { |doc| doc.delete }
            end
          end
        end
      end
    end
  end
end
