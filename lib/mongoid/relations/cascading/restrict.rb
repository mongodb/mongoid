# encoding: utf-8
module Mongoid
  module Relations
    module Cascading
      class Restrict < Base

        # Execute the cascading deletion for the relation if it already exists.
        # This should be optimized in the future potentially not to load all
        # objects from the db.
        #
        # @example Perform the cascading delete.
        #   strategy.cascade
        def cascade
          unless relation.blank?
            raise Errors::DeleteRestriction.new(document, metadata.name)
          end
        end
      end
    end
  end
end

