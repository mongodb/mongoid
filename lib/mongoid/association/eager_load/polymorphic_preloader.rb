# frozen_string_literal: true

require 'mongoid/association/eager_load/polymorphic_targets'

module Mongoid
  module Association
    module EagerLoad
      # Resolves a polymorphic belongs_to onto already-materialized root documents.
      #
      # A polymorphic belongs_to can't be expressed as a $lookup: its target
      # collection varies per document. So once the roots are materialized, the
      # foreign keys are grouped by type, PolymorphicTargets resolves the documents
      # for those keys, and the result is set on each document.
      class PolymorphicPreloader
        def initialize(association, root_class)
          @association = association
          @root_class = root_class
        end

        # Resolve and assign the polymorphic target on each of the documents.
        #
        # @param [ Array<Mongoid::Document> ] documents The materialized root documents.
        def preload_into(documents)
          targets = PolymorphicTargets.for(@association, keys_by_type(documents), @root_class)
          assign(documents, targets)
        end

        private

        # The foreign keys on the documents grouped by polymorphic type,
        # e.g. { "Printer" => [ id1 ], "Scanner" => [ id2 ] }.
        def keys_by_type(documents)
          documents.each_with_object({}) do |document, grouped|
            type, key = reference_on(document)
            (grouped[type] ||= []) << key if type && key
          end
        end

        def assign(documents, targets)
          documents.each do |document|
            type, key = reference_on(document)
            target = targets.dig(type, key) if type && key
            document.set_relation(@association.name, target)
          end
        end

        # The [ type, key ] reference stored on the document for this association,
        # or an empty pair when the document holds no such reference.
        def reference_on(document)
          type_field = @association.inverse_type
          key_field = @association.foreign_key
          return [] unless document.respond_to?(type_field) && document.respond_to?(key_field)

          [ document.send(type_field), document.send(key_field) ]
        end
      end
    end
  end
end
