# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides atomic $inc behaviour.
      class Inc
        include Operation

        # Sends the atomic $inc operation to the database.
        #
        # @example Persist the new values.
        #   inc.persist
        #
        # @return [ Object ] The new integer value.
        #
        # @since 2.0.0
        def persist
          prepare do
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
