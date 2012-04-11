# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This is the included module for all atomic operation objects.
      module Operation

        attr_accessor :document, :field, :value, :options

        # Get the collection to be used for persistence.
        #
        # @example Get the collection.
        #   operation.collection
        #
        # @return [ Collection ] The root collection.
        #
        # @since 2.1.0
        def collection
          document._root.collection
        end

        # Initialize the new pullAll operation.
        #
        # @example Create a new pullAll operation.
        #   PullAll.new(document, :aliases, [ "Bond" ])
        #
        # @param [ Document ] document The document to pullAll onto.
        # @param [ Symbol ] field The name of the array field.
        # @param [ Object ] value The value to pullAll.
        # @param [ Hash ] options The persistence options.
        #
        # @since 2.0.0
        def initialize(document, field, value, options = {})
          @document, @field, @value = document, field.to_s, value
          @options = options
        end

        # Get the atomic operation to perform.
        #
        # @example Get the operation.
        #   inc.operation
        #
        # @param [ String ] modifier The modifier to use.
        #
        # @return [ Hash ] The atomic operation for the field and addition.
        #
        # @since 2.0.0
        def operation(modifier)
          { modifier => { path => value } }
        end

        # Get the path to the field that is getting atomically updated.
        #
        # @example Get the path.
        #   operation.path
        #
        # @return [ String, Symbol ] The path to the field.
        #
        # @since 2.1.0
        def path
          position = document.atomic_position
          position.blank? ? field : "#{position}.#{field}"
        end

        # All atomic operations use this with a block to ensure saftey options
        # clear out after the execution.
        #
        # @example Prepare the operation.
        #   prepare do
        #     collection.update
        #   end
        #
        # @return [ Object ] The yielded value.
        #
        # @since 2.1.0
        def prepare
          doc = yield(document)
          Threaded.clear_options!
          doc
        end

        private

        # Executes the common functionality between operations.
        #
        # @api private
        #
        # @example Execute the operation.
        #   operation.execute("$push")
        #
        # @param [ String ] name The name of the operation.
        #
        # @since 3.0.0
        def execute(name)
          if document.persisted?
            collection.find(document.atomic_selector).update(operation(name))
            document.remove_change(field)
          end
        end

        # Appends items to an array and executes the corresponding $push or
        # $pushAll operation.
        #
        # @api private
        #
        # @example Execute the append.
        #   operation.append_with("$push")
        #
        # @param [ String ] name The name of the operation - $push or $pushAll.
        #
        # @since 3.0.0
        def append_with(name)
          prepare do
            document[field] = [] unless document[field]
            docs = document.send(field).concat(value.__array__)
            execute(name)
            docs
          end
        end
      end
    end
  end
end
