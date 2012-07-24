# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # This class provides atomic $inc behaviour.
      class Inc
        include Operation

        # Sends the atomic $inc operation to the database.
        #
        # @example Persist the new values.
        #   inc.persist
        #
        # @return [ Object ] The new numeric value.
        #
        # @since 2.0.0
        def persist
          prepare do
            self.value = value.to_f
            current = document[field] || 0
            document[field] = current + value
            execute("$inc")
            document[field]
          end
        end
      end
    end
  end
end
