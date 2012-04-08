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

    # Get the database sessions from the current thread.
    #
    # @example Get the database sessions.
    #   Threaded.sessions
    #
    # @return [ Hash ] The sessions.
    #
    # @since 3.0.0
    def sessions
      Thread.current[:"[mongoid]:sessions"] ||= {}
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

    # Begin autosaving a document on the current thread.
    #
    # @example Begin autosave.
    #   Threaded.begin_autosave(doc)
    #
    # @param [ Document ] document The document to autosave.
    #
    # @since 3.0.0
    def begin_autosave(document)
      autosaves_for(document.class).push(document.id)
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

    # Clear out all the persistence options.
    #
    # @example Clear out the persistence options.
    #   Threaded.clear_persistence_options(Band)
    #
    # @param [ Class ] klass The model class.
    #
    # @return [ true ] true.
    #
    # @since 2.0.0
    def clear_persistence_options(klass)
      Thread.current[:"[mongoid][#{klass}]:persistence-options"] = nil
      true
    end

    # Clear out all options set on a one-time basis.
    #
    # @example Clear out the options.
    #   Threaded.clear_options!
    #
    # @since 2.3.0
    def clear_options!
      self.timeless = false
    end

    # Exit autosaving a document on the current thread.
    #
    # @example Exit autosave.
    #   Threaded.exit_autosave(doc)
    #
    # @param [ Document ] document The document to autosave.
    #
    # @since 3.0.0
    def exit_autosave(document)
      autosaves_for(document.class).delete_one(document.id)
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

    # Is the identity map enabled on the current thread?
    #
    # @example Is the identity map enabled?
    #   Threaded.identity_map_enabled?
    #
    # @return [ true, false ] If the identity map is enabled.
    #
    # @since 3.0.0
    def identity_map_enabled?
      Thread.current[:"[mongoid]:identity-map-enabled"] != false
    end

    # Disable the identity map on either the current thread or all threads.
    #
    # @example Disable the identity map on all threads.
    #   Threaded.disable_identity_map(:all)
    #
    # @example Disable the identity map on the current thread.
    #   Threaded.disable_identity_map(:current)
    #
    # @param [ Symbol ] option The disabling option.
    #
    # @since 3.0.0
    def disable_identity_map(option)
      if option == :all
        Thread.list.each do |thread|
          thread[:"[mongoid]:identity-map-enabled"] = false
        end
      else
        Thread.current[:"[mongoid]:identity-map-enabled"] = false
      end
    end

    # Enable the identity map on either the current thread or all threads.
    #
    # @example Enable the identity map on all threads.
    #   Threaded.enable_identity_map(:all)
    #
    # @example Enable the identity map on the current thread.
    #   Threaded.enable_identity_map(:current)
    #
    # @param [ Symbol ] option The disabling option.
    #
    # @since 3.0.0
    def enable_identity_map(option)
      if option == :all
        Thread.list.each do |thread|
          thread[:"[mongoid]:identity-map-enabled"] = true
        end
      else
        Thread.current[:"[mongoid]:identity-map-enabled"] = true
      end
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

    # Get the persistence options for the current thread.
    #
    # @example Get the persistence options.
    #   Threaded.persistence_options(Band)
    #
    # @param [ Class ] klass The model class.
    #
    # @return [ Hash ] The current persistence options.
    #
    # @since 2.1.0
    def persistence_options(klass)
      Thread.current[:"[mongoid][#{klass}]:persistence-options"]
    end

    # Set the persistence options on the current thread.
    #
    # @example Set the persistence options.
    #   Threaded.set_persistence_options(Band, { safe: { fsync: true }})
    #
    # @param [ Class ] klass The model class.
    # @param [ Hash ] options The persistence options.
    #
    # @return [ Hash ] The persistence options.
    #
    # @since 2.1.0
    def set_persistence_options(klass, options)
      Thread.current[:"[mongoid][#{klass}]:persistence-options"] = options
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

    # Is the document autosaved on the current thread?
    #
    # @example Is the document autosaved?
    #   Threaded.autosaved?(doc)
    #
    # @param [ Document ] document The document to check.
    #
    # @return [ true, false ] If the document is autosaved.
    #
    # @since 2.1.9
    def autosaved?(document)
      autosaves_for(document.class).include?(document.id)
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

    # Get all autosaves on the current thread.
    #
    # @example Get all autosaves.
    #   Threaded.autosaves
    #
    # @return [ Hash ] The current autosaves.
    #
    # @since 3.0.0
    def autosaves
      Thread.current[:"[mongoid]:autosaves"] ||= {}
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

    # Get all autosaves on the current thread for the class.
    #
    # @example Get all autosaves.
    #   Threaded.autosaves_for(Person)
    #
    # @param [ Class ] The class to check.
    #
    # @return [ Array ] The current autosaves.
    #
    # @since 3.0.0
    def autosaves_for(klass)
      autosaves[klass] ||= []
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
