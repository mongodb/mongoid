# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $push modification
      # on a specific field.
      class Push

        attr_reader :document, :field, :value, :options

        # Initialize the new push operation.
        #
        # @example Create a new push operation.
        #   Push.new(document, :aliases, "Bond")
        #
        # @param [ Document ] document The document to push onto.
        # @param [ Symbol ] field The name of the array field.
        # @param [ Object ] value The value to push.
        # @param [ Hash ] options The persistence options.
        #
        # @since 2.0.0
        def initialize(document, field, value, options = {})
          @document, @field, @value, @options = document, field, value, options
        end

        # Sends the atomic $push operation to the database.
        #
        # @example Persist the new values.
        #   push.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          document[field] = [] unless document[field]
          document.send(field).push(value).tap do |value|
            document.collection.update(document._selector, operation, options)
            document.changes.delete(field.to_s)
          end
        end

        private

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   push.operation
        #
        # @return [ Hash ] The $push operation for the field and addition.
        #
        # @since 2.0.0
        def operation
          { "$push" => { field => value } }
        end
      end
    end
  end
end
