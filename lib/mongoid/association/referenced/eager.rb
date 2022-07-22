# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      module Eager

        # Base class for eager load preload functions.
        class Base

          # Instantiate the eager load class.
          #
          # @example Create the new belongs to eager load preloader.
          #   BelongsTo.new(association, parent_docs)
          #
          # @param [ Array<Association> ] associations Associations to eager load
          # @param [ Array<Document> ] docs Documents to preload the associations
          #
          # @return [ Base ] The eager load preloader
          def initialize(associations, docs)
            @associations = associations
            @docs = docs
            @grouped_docs = {}
          end

          # Run the preloader.
          #
          # @example Preload the associations into the documents.
          #   loader.run
          #
          # @return [ Array ] The list of documents given.
          def run
            @loaded = []
            while shift_association
              preload
              @loaded << @docs.collect { |d| d.send(@association.name) if d.respond_to?(@association.name) }
            end
            @loaded.flatten
          end

          protected

          # Preload the current association.
          #
          # This method should be implemented in the subclass
          #
          # @example Preload the current association into the documents.
          #   loader.preload
          def preload
            raise NotImplementedError
          end

          # Retrieves the documents referenced by the association, and
          # yields each one sequentially to the provided block. If the
          # association is not polymorphic, all documents are retrieved in
          # a single query. If the association is polymorphic, one query is
          # issued per association target class.
          def each_loaded_document(&block)
            each_loaded_document_of_class(@association.klass, keys_from_docs, &block)
          end

          # Retrieves the documents of the specified class, that have the
          # foreign key included in the specified list of keys.
          #
          # When the documents are retrieved, the set of inclusions applied
          # is the set of inclusions applied to the host document minus the
          # association that is being eagerly loaded.
          private def each_loaded_document_of_class(cls, keys)
            # Note: keys should not include nil elements.
            # Upstream code is responsible for eliminating nils from keys.
            return cls.none if keys.empty?

            criteria = cls.criteria
            criteria = criteria.apply_scope(@association.scope)
            criteria = criteria.any_in(key => keys)
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
          # @param [ Document | Array ] element to push into the parent
          def set_on_parent(id, element)
            grouped_docs[id].each do |d|
              set_relation(d, element)
            end
          end

          # Return a hash with the current documents grouped by key.
          #
          # Documents that do not have a value for the association being loaded
          # are not returned.
          #
          # @example Return a hash with the current documents grouped by key.
          #   loader.grouped_docs
          #
          # @return [ Hash ] hash with grouped documents.
          def grouped_docs
            @grouped_docs[@association.name] ||= @docs.group_by do |doc|
              doc.send(group_by_key) if doc.respond_to?(group_by_key)
            end.reject do |k, v|
              k.nil?
            end
          end

          # Group the documents and return the keys.
          #
          # This method omits nil keys (i.e. keys from documents that do not
          # have a value for the association being loaded).
          #
          # @example
          #   loader.keys_from_docs
          #
          # @return [ Array ] keys, ids
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
          def group_by_key
            raise NotImplementedError
          end

          # Set the pre-loaded document into its parent.
          #
          # @example Set docs into parent using the current association name.
          #   loader.set_relation(doc, docs)
          #
          # @param [ Document ] doc The object to set the association on
          # @param [ Document | Array ] element to set into the parent
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
          def shift_association
            @association = @associations.shift
          end
        end
      end
    end
  end
end
