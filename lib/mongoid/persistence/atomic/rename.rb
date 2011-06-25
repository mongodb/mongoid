# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # Performs an atomic rename operation.
      class Rename < Operation

        # Sends the atomic $inc operation to the database.
        #
        # @example Persist the new values.
        #   inc.persist
        #
        # @return [ Object ] The new integer value.
        #
        # @since 2.1.0
        def persist
          self.value, self.field = value.to_s, field.to_s
          document[value] = document.attributes.delete(field)
          document[value].tap do
            collection.update(document._selector, operation("$rename"), options)
            document.changes.delete(value)
          end
        end
      end
    end
  end
end
