# encoding: utf-8
module Mongoid #:nodoc:
  module Criterion #:nodoc:
    module EagerLoading
      # EagerLoading criterion are used when eager loading the associations.
      #
      # Example:
      #
      # <tt>criteria.includes(:user)</tt>
      #
      # <tt>criteria.includes(:user, :post)</tt>
      #
      # Returns: <tt>self</tt>
      attr_accessor :eager_loadings, :id_document_map, :id_associations_map

      def includes(*options)
        @eager_loadings = options
        self
      end

      def preload(documents)
        document_class = documents.first.class
        @eager_loadings.each do |eager_loading|
          setup_associations(documents, association_reflection(document_class, eager_loading))
        end
      end
      
      private
        def ignore_includes
          @eager_loadings = nil
        end

        def association_reflection(document_class, eager_loading)
          document_class.reflect_on_association(eager_loading)
        end

        def setup_associations(documents, reflection)
          if reflection.association == Mongoid::Associations::ReferencesOne
            setup_associations_with_ids(documents, reflection, true)
          elsif reflection.association == Mongoid::Associations::ReferencesMany
            setup_associations_with_ids(documents, reflection, false)
          elsif reflection.association == Mongoid::Associations::ReferencesManyAsArray
            setup_associations_with_foreign_keys(documents, reflection, false)
          elsif reflection.association == Mongoid::Associations::ReferencedIn
            setup_associations_with_foreign_keys(documents, reflection, true)
          end
        end

        def setup_associations_with_ids(documents, reflection, one=true)
          ids = []
          documents.each do |document|
            id_document_map[document.id] = document
            ids << document.id if document.id
          end

          association_class = reflection.name.singularize.camelize.constantize
          ignore_includes
          eager_associations = association_class.where(reflection.foreign_key.to_sym.in => ids).to_a
          eager_associations.each do |eager_association|
            add_id_association(eager_association.send(reflection.foreign_key), eager_association)
          end

          id_document_map.each do |id, document|
            document.send("#{reflection.name}=", one ? id_associations_map[id].first : id_associations_map[id])
          end
        end

        def setup_associations_with_foreign_keys(documents, reflection, one)
          ids = []
          foreign_key_name = reflection.foreign_key
          documents.each do |document|
            foreign_key_value = document.send(foreign_key_name)
            if one
              id_document_map[foreign_key_value] = document
              ids << foreign_key_value if foreign_key_value
            elsif foreign_key_value
              foreign_key_value.each do |fkv|
                id_document_map[fkv] = document
                ids << fkv if fkv
              end
            end
          end

          association_class = reflection.name.singularize.camelize.constantize
          ignore_includes
          eager_associations = association_class.find(ids).to_a
          eager_associations.each do |eager_association|
            add_id_association(eager_association.id, eager_association)
          end

          id_document_map.each do |id, document|
            foreign_key_value = document.send(foreign_key_name)
            associations = \
              if one
                id_associations_map[foreign_key_value].first
              else
                foreign_key_value.collect { |fkv| id_associations_map[fkv] }.flatten.uniq
              end
            document.send("#{reflection.name}=", associations)
          end
        end

        def id_document_map
          @id_doccument_map ||= {}
        end

        def id_associations_map
          @id_associations_map ||= {}
        end

        def add_id_association(id, association)
          id_associations_map[id] ||= []
          id_associations_map[id] << association
        end
    end
  end
end
