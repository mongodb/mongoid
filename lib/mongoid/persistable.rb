# encoding: utf-8
require "mongoid/persistable/creatable"

module Mongoid

  # Contains general behaviour for persistence operations.
  #
  # @since 2.0.0
  module Persistable
    include Creatable

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
  end
end
