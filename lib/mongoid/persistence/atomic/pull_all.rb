# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $pullAll
      # modification on a specific field.
      class PullAll < Operation

        # Sends the atomic $pullAll operation to the database.
        #
        # @example Persist the new values.
        #   pull_all.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          if document[field]
            values = document.send(field)
            values.delete_if { |val| value.include?(val) }
            values.tap do
              document.collection.update(document._selector, operation, options)
              document.changes.delete(field.to_s) if document.persisted?
            end
          else
            return nil
          end
        end

        private

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   pull_all.operation
        #
        # @return [ Hash ] The $pullAll operation for the field and addition.
        #
        # @since 2.0.0
        def operation
          { "$pullAll" => { field => value } }
        end
      end
    end
  end
end
