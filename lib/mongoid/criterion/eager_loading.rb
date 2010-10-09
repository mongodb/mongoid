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
      attr_accessor :eager_loadings

      def includes(*options)
        @eager_loadings = options
        self
      end

      def preload(documents)
        document_class = documents.first.class
        @eager_loadings.each do |eager_loading|
          reflection = association_reflection(document_class, eager_loading)
          setup_associations(documents, reflection)
        end
      end
      
      private
        def association_reflection(document_class, eager_loading)
          document_class.reflect_on_association(eager_loading)
        end

        def setup_associations(documents, reflection)
          if reflection.association == Mongoid::Associations::ReferencesOne
            setup_associations_with_ids(documents, reflection, :find)
          elsif reflection.association == Mongoid::Associations::ReferencesMany
            setup_associations_with_ids(documents, reflection, :find_all)
          elsif reflection.association == Mongoid::Associations::ReferencesManyAsArray
            setup_associations_with_foreign_keys(documents, reflection, :find_all)
          elsif reflection.association == Mongoid::Associations::ReferencedIn
            setup_associations_with_foreign_keys(documents, reflection, :find)
          end
        end

        def setup_associations_with_ids(documents, reflection, method)
          ids = documents.collect(&:id)
          eager_associations = reflection.name.singularize.camelize.constantize.where(reflection.foreign_key.to_sym.in => ids).to_a
          documents.each do |document|
            document.send("#{reflection.name}=", eager_associations.send(method) { |eager_association|
              eager_association.send(reflection.foreign_key) == document.id
            })
          end
        end

        def setup_associations_with_foreign_keys(documents, reflection, method)
          ids = documents.collect(&:"#{reflection.foreign_key}").compact.flatten
          eager_associations = reflection.name.singularize.camelize.constantize.find(ids).to_a
          documents.each do |document|
            document.send("#{reflection.name}=", eager_associations.send(method) { |eager_association|
              eager_association.id == document.send(reflection.foreign_key)
            })
          end
        end
    end
  end
end
