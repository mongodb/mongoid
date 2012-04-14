# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # This class provides the ability to perform an explicit $push modification
      # on a specific field.
      class Push
        include Operation

        # Sends the atomic $push operation to the database.
        #
        # @example Persist the new values.
        #   push.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          append_with("$push")
        end
      end
    end
  end
end
