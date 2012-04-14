# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # This class provides atomic $set behaviour.
      class Sets
        include Operation

        # Sends the atomic $set operation to the database.
        #
        # @example Persist the new values.
        #   set.persist
        #
        # @return [ Object ] The new field value.
        #
        # @ssete 2.0.0
        def persist
          prepare do
            document[field] = value
            execute("$set")
            document[field]
          end
        end
      end
    end
  end
end
