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
            collection.update(document.atomic_selector, operation("$rename"), options)
            document.remove_change(value)
            Threaded.clear_safety_options!
          end
        end
      end
    end
  end
end
