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
    include Creatable
    include Deletable
    include Destroyable
    include Incrementable
    include Logical
    include Poppable
    include Positional
    include Pullable
    include Pushable
    include Renamable
    include Savable
    include Settable
    include Updatable
    include Upsertable
    include Unsettable

    # The atomic operations that deal with arrays or sets in the db.
    #
    # @since 4.0.0
    LIST_OPERATIONS = [ "$addToSet", "$push", "$pull", "$pullAll" ].freeze

    # Execute operations atomically (in a single database call) for everything
    # that would happen inside the block.
    #
    # @example Execute the operations atomically.
    #   document.atomically do
    #     document.set(name: "Tool").inc(likes: 10)
    #   end
    #
    # @return [ true, false ] If the operation succeeded.
    #
    # @since 4.0.0
    def atomically
      begin
        @atomic_updates_to_execute = @atomic_updates_to_execute || {}
        yield(self) if block_given?
        persist_atomic_operations(@atomic_updates_to_execute)
        true
      ensure
        @atomic_updates_to_execute = nil
      end
    end

    # Raise an error if validation failed.
    #
    # @example Raise the validation error.
    #   Person.fail_due_to_validation!(person)
    #
    # @param [ Document ] document The document to fail.
    #
    # @raise [ Errors::Validations ] The validation error.
    #
    # @since 4.0.0
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
    # @since 4.0.0
    def fail_due_to_callback!(method)
      raise Errors::Callback.new(self.class, method)
    end

    private

    # Are we executing an atomically block on the current document?
    #
    # @api private
    #
    # @example Are we executing atomically?
    #   document.executing_atomically?
    #
    # @return [ true, false ] If we are current executing atomically.
    #
    # @since 4.0.0
    def executing_atomically?
      !@atomic_updates_to_execute.nil?
    end

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
      operations = yield({})
      persist_or_delay_atomic_operation(operations)
      self
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
    # @since 4.0.0
    def process_atomic_operations(operations)
      operations.each do |field, value|
        unless attribute_writable?(field)
          raise Errors::ReadonlyAttribute.new(field, value)
        end
        normalized = database_field_name(field)
        yield(normalized, value)
        remove_change(normalized)
      end
    end

    # If we are in an atomically block, add the operations to the delayed group,
    # otherwise persist immediately.
    #
    # @api private
    #
    # @example Persist immediately or delay the operations.
    #   document.persist_or_delay_atomic_operation(ops)
    #
    # @param [ Hash ] operation The operation.
    #
    # @since 4.0.0
    def persist_or_delay_atomic_operation(operation)
      if executing_atomically?
        operation.each do |(name, hash)|
          @atomic_updates_to_execute[name] ||= {}
          @atomic_updates_to_execute[name].merge!(hash)
        end
      else
        persist_atomic_operations(operation)
      end
    end

    # Persist the atomic operations.
    #
    # @api private
    #
    # @example Persist the atomic operations.
    #   persist_atomic_operations(ops)
    #
    # @param [ Hash ] operations The atomic operations.
    #
    # @since 4.0.0
    def persist_atomic_operations(operations)
      if persisted? && operations
        selector = atomic_selector
        _root.collection.find(selector).update_one(positionally(selector, operations))
      end
    end
  end
end
