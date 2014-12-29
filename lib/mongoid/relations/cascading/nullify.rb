# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Nullify < Base

        # This cascade does not delete the referenced relations, but instead
        # sets the foreign key values to nil.
        #
        # @example Nullify the reference.
        #   strategy.cascade
        def cascade
          relation.nullify if relation
        end
      end
    end
  end
end
