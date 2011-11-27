# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This class provides the ability to perform an explicit $addToSet
      # modification on a specific field.
      class AddAllToSet
        include Operation

        # Sends the atomic $addToSet operation to the database.
        #
        # @example Persist the new values.
        #   addToSet.persist
        #
        # @return [ Object ] The new array value.
        def persist
          prepare do
            document[field] = [] unless document[field]
            values = document.send(field)
            value.each do |val|
              values.push(val) unless values.include?(val)
            end

            @value = { '$each' => value }

            values.tap do
              if document.persisted?
                collection.update(document.atomic_selector, operation("$addToSet"), options)
                document.remove_change(field)
              end
            end
          end
        end
      end
    end
  end
end