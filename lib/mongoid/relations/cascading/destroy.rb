# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Cascading #:nodoc:
      class Destroy < Strategy

        # Execute the cascading deletion for the relation if it already exists.
        # This should be optimized in the future potentially not to load all
        # objects from the db.
        #
        # @example Perform the cascading destroy.
        #   strategy.cascade
        def cascade
          relation.to_a.each { |doc| doc.destroy } if relation
        end
      end
    end
  end
end
