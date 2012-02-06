# encoding: utf-8
require "mongoid/threaded/lifecycle"

module Mongoid #:nodoc:

  # This module contains logic for easy access to objects that have a lifecycle
  # on the current thread.
  module Threaded
    extend self

    # Begin entry into a named thread local stack.
    #
    # @example Begin entry into the stack.
    #   Threaded.begin(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ true ] True.
    #
    # @since 2.4.0
    def begin(name)
      stack(name).push(true)
    end

    # Are in the middle of executing the named stack
    #
    # @example Are we in the stack execution?
    #   Threaded.executing?(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ true ] If the stack is being executed.
    #
    # @since 2.4.0
    def executing?(name)
      !stack(name).empty?
    end

    # Exit from a named thread local stack.
    #
    # @example Exit from the stack.
    #   Threaded.exit(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ true ] True.
    #
    # @since 2.4.0
    def exit(name)
      stack(name).pop
    end

    # Get the named stack.
    #
    # @example Get a stack by name
    #   Threaded.stack(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ Array ] The stack.
    #
    # @since 2.4.0
    def stack(name)
      Thread.current[:"[mongoid]:#{name}-stack"] ||= []
    end

    # Begin validating a document on the current thread.
    #
    # @example Begin validation.
    #   Threaded.begin_validate(doc)
    #
    # @param [ Document ] document The document to validate.
    #
    # @since 2.1.9
    def begin_validate(document)
      validations_for(document.class).push(document.id)
    end

    # Clear out all the safety options set using the safely proxy.
    #
    # @example Clear out the options.
    #   Threaded.clear_safety_options!
    #
    # @return [ nil ] nil
    #
    # @since 2.1.0
    def clear_safety_options!
      Thread.current[:"[mongoid]:safety-options"] = nil
    end

    # Clear out all options set on a one-time basis.
    #
    # @example Clear out the options.
    #   Threaded.clear_options!
    #
    # @since 2.3.0
    def clear_options!
      clear_safety_options!
      self.timeless = false
    end

    # Exit validating a document on the current thread.
    #
    # @example Exit validation.
    #   Threaded.exit_validate(doc)
    #
    # @param [ Document ] document The document to validate.
    #
    # @since 2.1.9
    def exit_validate(document)
      validations_for(document.class).delete_one(document.id)
    end

    # Get the identity map off the current thread.
    #
    # @example Get the identity map.
    #   Threaded.identity_map
    #
    # @return [ IdentityMap ] The identity map.
    #
    # @since 2.1.0
    def identity_map
      Thread.current[:"[mongoid]:identity-map"] ||= IdentityMap.new
    end

    # Get the insert consumer from the current thread.
    #
    # @example Get the insert consumer.
    #   Threaded.insert
    #
    # @return [ Object ] The batch insert consumer.
    #
    # @since 2.1.0
    def insert(name)
      Thread.current[:"[mongoid][#{name}]:insert-consumer"]
    end

    # Set the insert consumer on the current thread.
    #
    # @example Set the insert consumer.
    #   Threaded.insert = consumer
    #
    # @param [ Object ] consumer The insert consumer.
    #
    # @return [ Object ] The insert consumer.
    #
    # @since 2.1.0
    def set_insert(name, consumer)
      Thread.current[:"[mongoid][#{name}]:insert-consumer"] = consumer
    end

    # Get the safety options for the current thread.
    #
    # @example Get the safety options.
    #   Threaded.safety_options
    #
    # @return [ Hash ] The current safety options.
    #
    # @since 2.1.0
    def safety_options
      Thread.current[:"[mongoid]:safety-options"]
    end

    # Set the safety options on the current thread.
    #
    # @example Set the safety options.
    #   Threaded.safety_options = { :fsync => true }
    #
    # @param [ Hash ] options The safety options.
    #
    # @return [ Hash ] The safety options.
    #
    # @since 2.1.0
    def safety_options=(options)
      Thread.current[:"[mongoid]:safety-options"] = options
    end

    # Get the field selection options from the current thread.
    #
    # @example Get the field selection options.
    #   Threaded.selection
    #
    # @return [ Hash ] The field selection.
    #
    # @since 2.4.4
    def selection
      Thread.current[:"[mongoid]:selection"]
    end

    # Set the field selection on the current thread.
    #
    # @example Set the field selection.
    #   Threaded.selection = { field: 1 }
    #
    # @param [ Hash ] value The current field selection.
    #
    # @return [ Hash ] The field selection.
    #
    # @since 2.4.4
    def selection=(value)
      Thread.current[:"[mongoid]:selection"] = value
    end

    # Get the mongoid scope stack for chained criteria.
    #
    # @example Get the scope stack.
    #   Threaded.scope_stack
    #
    # @return [ Hash ] The scope stack.
    #
    # @since 2.1.0
    def scope_stack
      Thread.current[:"[mongoid]:scope-stack"] ||= {}
    end

    # Get the value of the one-off timeless call.
    #
    # @example Get the timeless value.
    #   Threaded.timeless
    #
    # @return [ true, false ] The timeless setting.
    #
    # @since 2.3.0
    def timeless
      !!Thread.current[:"[mongoid]:timeless"]
    end

    # Set the value of the one-off timeless call.
    #
    # @example Set the timeless value.
    #   Threaded.timeless = true
    #
    # @param [ true, false ] value The value.
    #
    # @since 2.3.0
    def timeless=(value)
      Thread.current[:"[mongoid]:timeless"] = value
    end

    # Get the update consumer from the current thread.
    #
    # @example Get the update consumer.
    #   Threaded.update
    #
    # @return [ Object ] The atomic update consumer.
    #
    # @since 2.1.0
    def update_consumer(klass)
      Thread.current[:"[mongoid][#{klass}]:update-consumer"]
    end

    # Set the update consumer on the current thread.
    #
    # @example Set the update consumer.
    #   Threaded.update = consumer
    #
    # @param [ Object ] consumer The update consumer.
    #
    # @return [ Object ] The update consumer.
    #
    # @since 2.1.0
    def set_update_consumer(klass, consumer)
      Thread.current[:"[mongoid][#{klass}]:update-consumer"] = consumer
    end

    # Is the current thread setting timestamps?
    #
    # @example Is the current thread timestamping?
    #   Threaded.timestamping?
    #
    # @return [ true, false ] If timestamps can be applied.
    #
    # @since 2.3.0
    def timestamping?
      !timeless
    end

    # Is the document validated on the current thread?
    #
    # @example Is the document validated?
    #   Threaded.validated?(doc)
    #
    # @param [ Document ] document The document to check.
    #
    # @return [ true, false ] If the document is validated.
    #
    # @since 2.1.9
    def validated?(document)
      validations_for(document.class).include?(document.id)
    end

    # Get all validations on the current thread.
    #
    # @example Get all validations.
    #   Threaded.validations
    #
    # @return [ Hash ] The current validations.
    #
    # @since 2.1.9
    def validations
      Thread.current[:"[mongoid]:validations"] ||= {}
    end

    # Get all validations on the current thread for the class.
    #
    # @example Get all validations.
    #   Threaded.validations_for(Person)
    #
    # @param [ Class ] The class to check.
    #
    # @return [ Array ] The current validations.
    #
    # @since 2.1.9
    def validations_for(klass)
      validations[klass] ||= []
    end
  end
end
