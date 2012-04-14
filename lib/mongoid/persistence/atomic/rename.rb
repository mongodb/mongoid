# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # Performs an atomic rename operation.
      class Rename
        include Operation

        # Sends the atomic $inc operation to the database.
        #
        # @example Persist the new values.
        #   inc.persist
        #
        # @return [ Object ] The new integer value.
        #
        # @since 2.1.0
        def persist
          prepare do
            @value = value.to_s
            document[value] = document.attributes.delete(field)
            execute("$rename")
            document.remove_change(value)
            document[value]
          end
        end
      end
    end
  end
end
