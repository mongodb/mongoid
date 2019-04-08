# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      module Eager

        # Base class for eager load preload functions.
        #
        # @since 4.0.0
        class Base

          # Instantiate the eager load class.
          #
          # @example Create the new belongs to eager load preloader.
          #   BelongsTo.new(association, parent_docs)
          #
          # @param [ Array<Association> ] associations Associations to eager load
          # @param [ Array<Document> ] docs Documents to preload the relations
          #
          # @return [ Base ] The eager load preloader
          #
          # @since 4.0.0
          def initialize(associations, docs)
            @associations = associations
            @docs = docs
            @grouped_docs = {}
          end

          # Run the preloader.
          #
          # @example Preload the relations into the documents.
          #   loader.run
          #
          # @return [ Array ] The list of documents given.
          #
          # @since 4.0.0
          def run
            @loaded = []
            while shift_association
              preload
              @loaded << @docs.collect { |d| d.send(@association.name) if d.respond_to?(@association.name) }
            end
            @loaded.flatten
          end

          protected

          # Preload the current relation.
          #
          # This method should be implemented in the subclass
          #
          # @example Preload the current relation into the documents.
          #   loader.preload
          #
          # @since 4.0.0
          def preload
            raise NotImplementedError
          end

          # Run the preloader.
          #
          # @example Iterate over the documents loaded for the current relation
          #   loader.each_loaded_document { |doc| }
          #
          # @since 4.0.0
          def each_loaded_document
            doc_keys = keys_from_docs
            return @association.klass.none if doc_keys.all?(&:nil?)

            criteria = @association.klass.any_in(key => doc_keys)
            criteria.inclusions = criteria.inclusions - [@association]
            criteria.each do |doc|
              yield doc
            end
          end

          # Set the pre-loaded document into its parent.
          #
          # @example Set docs into parent with pk = "foo"
          #   loader.set_on_parent("foo", docs)
          #
          # @param [ ObjectId ] id parent`s id
          # @param [ Document, Array ] element to push into the parent
          #
          # @since 4.0.0
          def set_on_parent(id, element)
            grouped_docs[id].each do |d|
              set_relation(d, element)
            end
          end

          # Return a hash with the current documents grouped by key.
          #
          # @example Return a hash with the current documents grouped by key.
          #   loader.grouped_docs
          #
          # @return [ Hash ] hash with grouped documents.
          #
          # @since 4.0.0
          def grouped_docs
            @grouped_docs[@association.name] ||= @docs.group_by do |doc|
              doc.send(group_by_key) if doc.respond_to?(group_by_key)
            end
          end

          # Group the documents and return the keys
          #
          # @example
          #   loader.keys_from_docs
          #
          # @return [ Array ] keys, ids
          #
          # @since 4.0.0
          def keys_from_docs
            grouped_docs.keys
          end

          # Return the key to group the current documents.
          #
          # This method should be implemented in the subclass
          #
          # @example Return the key for group
          #   loader.group_by_key
          #
          # @return [ Symbol ] Key to group by the current documents.
          #
          # @since 4.0.0
          def group_by_key
            raise NotImplementedError
          end

          # Set the pre-loaded document into its parent.
          #
          # @example Set docs into parent using the current relation name.
          #   loader.set_relation(doc, docs)
          #
          # @param [ Document ] doc The object to set the relation on
          # @param [ Document, Array ] element to set into the parent
          #
          # @since 4.0.0
          def set_relation(doc, element)
            doc.set_relation(@association.name, element) unless doc.blank?
          end

          private

          # Shift the current association metadata
          #
          # @example Shift the current association.
          #   loader.shift_association
          #
          # @return [ Association ] The association object.
          #
          # @since 4.0.0
          def shift_association
            @association = @associations.shift
          end
        end
      end
    end
  end
end
