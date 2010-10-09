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
          if reflection.association == Mongoid::Associations::ReferencesOne
            ids = documents.collect(&:id)
            eager_associations = reflection.name.singularize.camelize.constantize.where(reflection.foreign_key.to_sym.in => ids).to_a
            documents.each do |document|
              document.send("#{reflection.name}=", eager_associations.find { |eager_association|
                eager_association.send(reflection.foreign_key) == document.id
              })
            end
          elsif reflection.association == Mongoid::Associations::ReferencesMany
            ids = documents.collect(&:id)
            eager_associations = reflection.name.singularize.camelize.constantize.where(reflection.foreign_key.to_sym.in => ids).to_a
            documents.each do |document|
              document.send("#{reflection.name}=", eager_associations.find_all { |eager_association|
                eager_association.send(reflection.foreign_key) == document.id
              })
            end
          elsif reflection.association == Mongoid::Associations::ReferencedIn
            ids = documents.collect(&:"#{reflection.foreign_key}")
            eager_associations = reflection.name.singularize.camelize.constantize.find(ids).to_a
            documents.each do |document|
              document.send("#{reflection.name}=", eager_associations.find { |eager_association|
                eager_association.id == document.send(reflection.foreign_key)
              })
            end
          else
          end
        end
      end
      
      def association_reflection(document_class, eager_loading)
        document_class.reflect_on_association(eager_loading)
      end
    end
  end
end
