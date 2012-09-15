# encoding: utf-8
module Mongoid
  module Contextual
    module Eager

      # @attribute [rw] eager_loaded Has the context been eager loaded?
      attr_accessor :eager_loaded

      private

      # Eager load the inclusions for the provided documents.
      #
      # @example Eager load the inclusions.
      #   context.eager_load(docs)
      #
      # @param [ Array<Document> ] docs The docs returning from the db.
      #
      # @return [ true ] Always true.
      #
      # @since 3.0.0
      def eager_load(docs)
        criteria.inclusions.reject! do |metadata|
          metadata.eager_load(eager_loaded_ids(docs, metadata)) if !docs.empty?
        end
        self.eager_loaded = true
      end

      # Get the ids that to be used to eager load documents.
      #
      # @api private
      #
      # @example Get the ids.
      #   context.eager_load(docs, metadata)
      #
      # @param [ Array<Document> ] docs The pre-loaded documents.
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ Array<Object> ] The ids.
      #
      # @since 3.0.0
      def eager_loaded_ids(docs, metadata)
        if metadata.stores_foreign_key?
          docs.flat_map{ |doc| doc.send(metadata.foreign_key) }
        else
          docs.map(&:id)
        end
      end

      # Is this context able to be eager loaded?
      #
      # @example Is the context eager loadable?
      #   context.eager_loadable?
      #
      # @return [ true, false ] If the context is able to be eager loaded.
      #
      # @since 3.0.0
      def eager_loadable?
        !eager_loaded && !criteria.inclusions.empty?
      end

      # If the provided document exists, eager load it's dependencies or return
      # nil.
      #
      # @example Eager load if the document is not nil.
      #   context.with_eager_loading(document)
      #
      # @param [ Hash ] document The document from the database.
      #
      # @return [ Document, nil ] The instantiated model document.
      #
      # @since 3.0.0
      def with_eager_loading(document)
        selecting do
          return nil unless document
          doc = Factory.from_db(klass, document, criteria.object_id)
          eager_load([ doc ]) if eager_loadable?
          doc
        end
      end
    end
  end
end
