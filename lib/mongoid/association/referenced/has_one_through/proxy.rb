# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOneThrough
        # Read-only proxy for has_one :through associations.
        # Instances are returned by the association getter. Write attempts raise
        # ReadonlyAssociation.
        class Proxy < Association::One
          module ClassMethods
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            # Returns true if the association is an embedded one. In this case
            # always false.
            #
            # @return [ false ] Always false.
            def embedded?
              false
            end
          end

          extend ClassMethods
        end
      end
    end
  end
end
