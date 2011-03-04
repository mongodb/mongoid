# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $addToSet
      # modification on a specific field.
      class AddToSet

        attr_reader :document, :field, :value, :options

        # Initialize the new addToSet operation.
        #
        # @example Create a new addToSet operation.
        #   AddToSet.new(document, :aliases, "Bond")
        #
        # @param [ Document ] document The document to addToSet onto.
        # @param [ Symbol ] field The name of the array field.
        # @param [ Object ] value The value to addToSet.
        # @param [ Hash ] options The persistence options.
        #
        # @since 2.0.0
        def initialize(document, field, value, options = {})
          @document, @field, @value, @options = document, field, value, options
        end

        # Sends the atomic $addToSet operation to the database.
        #
        # @example Persist the new values.
        #   addToSet.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          document[field] = [] unless document[field]
          values = document.send(field)
          values.push(value) unless values.include?(value)
          values.tap do
            document.collection.update(document._selector, operation, options)
            document.changes.delete(field.to_s)
          end
        end

        private

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   addToSet.operation
        #
        # @return [ Hash ] The $addToSet operation for the field and addition.
        #
        # @since 2.0.0
        def operation
          { "$addToSet" => { field => value } }
        end
      end
    end
  end
end
