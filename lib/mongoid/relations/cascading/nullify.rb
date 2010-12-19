# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cascading #:nodoc:
      class Nullify < Strategy

        # This cascade does not delete the referenced relations, but instead
        # sets the foreign key values to nil.
        #
        # @example Nullify the reference.
        #   strategy.cascade
        def cascade
          relation.to_a.each do |doc|
            if metadata.macro == :references_and_referenced_in_many
              document.send(metadata.foreign_key).delete(doc.id)
              doc.send(metadata.inverse_foreign_key).delete(document.id)
            else
              doc.send(metadata.foreign_key_setter, nil)
            end
            doc.save
          end
        end
      end
    end
  end
end
