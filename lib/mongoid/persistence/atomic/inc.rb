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
            current = document[field] || 0
            document[field] = current + value
            execute("$inc")
            document[field]
          end
        end

        private

        # In case we need to cast going to the database.
        #
        # @api private
        #
        # @example Cast the value.
        #   operation.cast_value
        #
        # @return [ Integer, Float ] The value casted.
        #
        # @since 3.0.3
        def cast_value
          value.__to_inc__
        end
      end
    end
  end
end
