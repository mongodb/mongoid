# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Destroy < Base

        # Execute the cascading deletion for the relation if it already exists.
        # This should be optimized in the future potentially not to load all
        # objects from the db.
        #
        # @example Perform the cascading destroy.
        #   strategy.cascade
        def cascade
          if relation
            if relation.is_a?(Enumerable)
              relation.entries
              relation.each { |doc| doc.destroy }
            else
              relation.destroy
            end
          end
        end
      end
    end
  end
end
