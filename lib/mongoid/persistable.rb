# encoding: utf-8
require "mongoid/persistable/atomic"
require "mongoid/persistable/creatable"
require "mongoid/persistable/deletable"
require "mongoid/persistable/destroyable"
require "mongoid/persistable/savable"
require "mongoid/persistable/settable"
require "mongoid/persistable/updatable"
require "mongoid/persistable/upsertable"

module Mongoid

  # Contains general behaviour for persistence operations.
  #
  # @since 2.0.0
  module Persistable
    extend ActiveSupport::Concern
    include Atomic
    include Mongoid::Atomic::Positionable
    include Creatable
    include Deletable
    include Destroyable
    include Savable
    include Settable
    include Updatable
    include Upsertable

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
    #   document.prepare_atomic_operation do |opts|
    #   end
    #
    # @return [ Object ] The result of the operation.
    #
    # @since 4.0.0
    def prepare_atomic_operation
      # @todo: Check if the document is persisted here.
      yield({}) if block_given?
      Threaded.clear_options!
      true
    end
  end
end
