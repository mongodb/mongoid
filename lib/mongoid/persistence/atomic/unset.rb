# encoding: utf-8
module Mongoid
  module Persistence
    module Atomic

      # Performs atomic $unset operations.
      class Unset
        include Operation

        # Sends the atomic $unset operation to the database.
        #
        # @example Persist the new values.
        #   unset.persist
        #
        # @return [ nil ] The new value.
        #
        # @since 2.1.0
        def persist
          prepare do
            fields.each { |f| document.attributes.delete(f) }
            execute("$unset")
          end
        end
      end
    end
  end
end
