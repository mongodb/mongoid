# encoding: utf-8
module Mongoid #:nodoc:
  module Persistence #:nodoc:
    module Atomic #:nodoc:

      # This is the superclass for all atomic operation objects.
      class Operation
        include Mongoid::Safe

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
          @document, @field, @value = document, field, value
          @options = { :safe => safe_mode?(options) }
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
          position = document._position
          position.blank? ? field : "#{position}.#{field}"
        end
      end
    end
  end
end
