# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # This class provides the ability to perform an explicit $pop
      # modification on a specific field.
      class Pop
        include Operation

        # Sends the atomic $pop operation to the database.
        #
        # @example Persist the new values.
        #   pop.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.1.0
        def persist
          prepare do
            if document[field]
              values = document.send(field)
              value > 0 ? values.pop : values.shift
              execute("$pop")
              values
            end
          end
        end
      end
    end
  end
end
