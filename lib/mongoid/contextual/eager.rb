# encoding: utf-8
module Mongoid
  module Contextual
    module Eager

      # @attribute [rw] eager_loaded Has the context been eager loaded?
      attr_accessor :eager_loaded

      private

      # Eager load the inclusions for the provided documents.
      #
      # @api private
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
        load_inclusions(docs)
        self.eager_loaded = true
      end

      # Eager load the inclusions for the provided document.
      #
      # @api private
      #
      # @example Eager load the inclusions.
      #   context.eager_load(doc)
      #
      # @param [ Document ] doc The doc returning from the db.
      #
      # @return [ true ] Always true.
      #
      # @since 3.0.16
      def eager_load_one(doc)
        load_inclusions([ doc ])
        inclusions_loaded[doc.id] = true
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
      # @api private
      #
      # @example Is the context eager loadable?
      #   context.eager_loadable?
      #
      # @example Is the single document eager loadable?
      #   context.eager_loadable?(document)
      #
      # @param [ Document ] document The single document to load for.
      #
      # @return [ true, false ] If the context is able to be eager loaded.
      #
      # @since 3.0.0
      def eager_loadable?(document = nil)
        return false if criteria.inclusions.empty?
        document ? !inclusions_loaded?(document) : !eager_loaded
      end

      # Has a hash of individual documents that have had their relations reager
      # loaded.
      #
      # @api private
      #
      # @example Get the documents with relations eager loaded.
      #   context.inclusions_loaded
      #
      # @return [ Hash ] The documents that have had eager loaded inclusions.
      #
      # @since 3.0.16
      def inclusions_loaded
        @inclusions_loaded ||= {}
      end

      # Has the document had its inclusions loaded?
      #
      # @api private
      #
      # @example Has the document had its inclusions loaded?
      #   context.inclusions_loaded?(document)
      #
      # @param [ Document ] document The document to check.
      #
      # @return [ true, false ] If the document had it's inclusions loaded.
      #
      # @since 3.0.16
      def inclusions_loaded?(document)
        inclusions_loaded.has_key?(document.id)
      end

      # Eager load the inclusions for the provided documents.
      #
      # @api private
      #
      # @example Eager load the inclusions.
      #   context.load_inclusions(docs)
      #
      # @param [ Array<Document> ] docs The docs returning from the db.
      #
      # @return [ true ] Always true.
      #
      # @since 3.0.16
      def load_inclusions(docs)
        criteria.inclusions.each do |metadata|
          metadata.eager_load(eager_loaded_ids(docs, metadata)) if !docs.empty?
        end
      end

      # If the provided document exists, eager load its dependencies or return
      # nil.
      #
      # @api private
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
          eager_load_one(doc) if eager_loadable?(doc)
          doc
        end
      end
    end
  end
end
