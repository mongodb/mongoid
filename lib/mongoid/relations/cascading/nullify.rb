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
            doc.send(metadata.foreign_key_setter, nil)
            doc.save
          end
        end
      end
    end
  end
end
