# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $addToSet
      # modification on a specific field.
      class AddToSet
        include Operation

        # Sends the atomic $addToSet operation to the database.
        #
        # @example Persist the new values.
        #   addToSet.persist
        #
        # @return [ Object ] The new array value.
        #
        # @since 2.0.0
        def persist
          prepare do
            document[field] = [] unless document[field]
            values = document.send(field)
            Array.wrap(value).each do |val|
              values.push(val) unless values.include?(val)
            end
            values.tap do
              if document.persisted?
                collection.update(document.atomic_selector, operation("$addToSet"), options)
                document.remove_change(field)
              end
            end
          end
        end

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   add_to_set.operation("$addToSet")
        #
        # @param [ String ] modifier The modifier to use.
        #
        # @return [ Hash ] The atomic operation for the field and addition.
        #
        # @since 2.0.0
        def operation(modifier)
          { modifier => { path => value.is_a?(Array) ? { "$each" => value } : value}}
        end
      end
    end
  end
end
