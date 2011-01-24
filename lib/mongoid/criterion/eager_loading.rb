module Mongoid
  module Criterion
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
      attr_accessor :eager_loadings, :id_documents_map, :id_associations_map

      def includes(*options)
        @eager_loadings = options
        self
      end

      def preload(documents)
        return if documents.blank?
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
          case reflection.macro
          when :references_one
            setup_associations_with_ids(documents, reflection, true)
          when :references_many
            setup_associations_with_ids(documents, reflection, false)
          when :references_and_referenced_in_many
            setup_associations_with_foreign_keys(documents, reflection, false)
          when :referenced_in
            setup_associations_with_foreign_keys(documents, reflection, true)
          end
        end

        def setup_associations_with_ids(documents, reflection, one)
          ids = association_ids(documents, reflection)

          ignore_includes
          eager_associations = reflection.klass.where(reflection.foreign_key.to_sym.in => ids.uniq).to_a
          eager_associations.each do |eager_association|
            add_id_association(eager_association.send(reflection.foreign_key), eager_association)
          end

          assign_associations(documents, reflection, one)
        end

        def setup_associations_with_foreign_keys(documents, reflection, one)
          ids = association_ids(documents, reflection)

          ignore_includes
          eager_associations = reflection.klass.find(ids.uniq).to_a
          eager_associations.each do |eager_association|
            add_id_association(eager_association.id, eager_association)
          end

          assign_associations(documents, reflection, one)
        end

        def association_ids(documents, reflection)
          ids = []
          key_name = reflection.key
          documents.each do |document|
            key_value = document.send(key_name)
            to_array(key_value).each do |v|
              add_id_document(v, document)
              ids << v
            end
          end
          ids
        end

        def assign_associations(documents, reflection, one)
          id_documents_map.each do |id, documents|
            documents.each do |document|
              key_value = document.send(reflection.key)
              associations = \
                if one
                  id_associations_map[key_value] ? id_associations_map[key_value].first : nil
                else
                  to_array(key_value).collect { |v| id_associations_map[v] }.compact.flatten
                end
              document.instance_variable_set("@#{reflection.name}", associations)
            end
          end
        end

        def to_array(value)
          array = value.is_a?(Array) ? value : [value]
          array.compact
        end

        def id_documents_map
          @id_documents_map ||= {}
        end

        def id_associations_map
          @id_associations_map ||= {}
        end

        def add_id_document(id, document)
          id_documents_map[id] ||= []
          id_documents_map[id] << document
        end

        def add_id_association(id, association)
          id_associations_map[id] ||= []
          id_associations_map[id] << association
        end
    end
  end
end
