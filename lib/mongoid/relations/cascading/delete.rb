# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Delete < Base

        # Execute the cascading deletion for the relation if it already exists.
        # This should be optimized in the future potentially not to load all
        # objects from the db.
        #
        # @example Perform the cascading delete.
        #   strategy.cascade
        #
        # @since 2.0.0
        def cascade
          if relation
            if relation.cascades.empty?
              relation.clear
            else
              ::Array.wrap(relation).each { |doc| doc.delete }
            end
          end
        end
      end
    end
  end
end
