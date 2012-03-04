# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This module provides common push behaviour.
      module Pushable
        include Operation

        # Push the value onto the existing field, and execute the provided
        # command.
        #
        # @example Push the value(s).
        #   pushable.push("$pushAll")
        #
        # @param [ String ] command The atomic operation, $push or $pushAll.
        #
        # @return [ Array ] The new field value.
        #
        # @since 3.0.0
        def push(command)
          prepare do
            document[field] = [] unless document[field]
            document.send(field).concat(Array(value)).tap do |value|
              collection.update(document.atomic_selector, operation(command), options)
              document.remove_change(field)
            end
          end
        end
      end
    end
  end
end
