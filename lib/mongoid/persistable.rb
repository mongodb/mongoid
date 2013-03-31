# encoding: utf-8
require "mongoid/persistable/creatable"
require "mongoid/persistable/deletable"
require "mongoid/persistable/savable"
require "mongoid/persistable/updatable"

module Mongoid

  # Contains general behaviour for persistence operations.
  #
  # @since 2.0.0
  module Persistable
    include Creatable
    include Deletable
    include Savable
    include Updatable

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
  end
end
