# encoding: utf-8
require "mongoid/persistable/creatable"
require "mongoid/persistable/deletable"
require "mongoid/persistable/destroyable"
require "mongoid/persistable/incrementable"
require "mongoid/persistable/logical"
require "mongoid/persistable/poppable"
require "mongoid/persistable/pullable"
require "mongoid/persistable/pushable"
require "mongoid/persistable/renamable"
require "mongoid/persistable/savable"
require "mongoid/persistable/settable"
require "mongoid/persistable/updatable"
require "mongoid/persistable/upsertable"
require "mongoid/persistable/unsettable"

module Mongoid

  # Contains general behaviour for persistence operations.
  #
  # @since 2.0.0
  module Persistable
    extend ActiveSupport::Concern
    include Mongoid::Atomic::Positionable
    include Creatable
    include Deletable
    include Destroyable
    include Incrementable
    include Logical
    include Poppable
    include Pullable
    include Pushable
    include Renamable
    include Savable
    include Settable
    include Updatable
    include Upsertable
    include Unsettable

    # Raise an error if validation failed.
    #
    # @example Raise the validation error.
    #   Person.fail_due_to_validation!(person)
    #
    # @param [ Document ] document The document to fail.
    #
    # @raise [ Errors::Validations ] The validation error.
    #
    # @since 2.0.0
    def fail_due_to_validation!
      raise Errors::Validations.new(self)
    end

    # Raise an error if a callback failed.
    #
    # @example Raise the callback error.
    #   Person.fail_due_to_callback!(person, :create!)
    #
    # @param [ Document ] document The document to fail.
    # @param [ Symbol ] method The method being called.
    #
    # @raise [ Errors::Callback ] The callback error.
    #
    # @since 2.2.0
    def fail_due_to_callback!(method)
      raise Errors::Callback.new(self.class, method)
    end

    private

    # Post process the persistence operation.
    #
    # @api private
    #
    # @example Post process the persistence operation.
    #   document.post_process_persist(true)
    #
    # @param [ Object ] result The result of the operation.
    # @param [ Hash ] options The options.
    #
    # @return [ true ] true.
    #
    # @since 4.0.0
    def post_process_persist(result, options = {})
      post_persist unless result == false
      errors.clear unless performing_validations?(options)
      true
    end

    # Prepare an atomic persistence operation. Yields an empty hash to be sent
    # to the update.
    #
    # @api private
    #
    # @example Prepare the atomic operation.
    #   document.prepare_atomic_operation do |coll, selector, opts|
    #     ...
    #   end
    #
    # @return [ Object ] The result of the operation.
    #
    # @since 4.0.0
    def prepare_atomic_operation
      # @todo: Check if the document is persisted here.
      yield(_root.collection, atomic_selector, {}) if block_given?
      Threaded.clear_options!
      true
    end

    # Process the atomic operations - this handles the common behaviour of
    # iterating through each op, getting the aliased field name, and removing
    # appropriate dirty changes.
    #
    # @api private
    #
    # @example Process the atomic operations.
    #   document.process_atomic_operations(pulls) do |field, value|
    #     ...
    #   end
    #
    # @param [ Hash ] operations The atomic operations.
    #
    # @return [ Hash ] The operations.
    #
    # @since 3.0.0
    def process_atomic_operations(operations)
      operations.each do |field, value|
        normalized = database_field_name(field)
        yield(normalized, value)
        remove_change(normalized)
      end
    end
  end
end
