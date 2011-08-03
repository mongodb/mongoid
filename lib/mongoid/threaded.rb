# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains logic for easy access to objects that have a lifecycle
  # on the current thread.
  module Threaded
    extend self

    # Is the current thread in binding mode?
    #
    # @example Is the thread in binding mode?
    #   Threaded.binding?
    #
    # @return [ true, false ] If the thread is in binding mode?
    #
    # @since 2.1.0
    def binding?
      Thread.current[:"[mongoid]:binding-mode"] ||= false
    end

    # Set the binding mode for the current thread.
    #
    # @example Set the binding mode.
    #   Threaded.binding = true
    #
    # @param [ true, false ] mode The current binding mode.
    #
    # @return [ true, false ] The current binding mode.
    #
    # @since 2.1.0
    def binding=(mode)
      Thread.current[:"[mongoid]:binding-mode"] = mode
    end

    # Is the current thread in building mode?
    #
    # @example Is the thread in building mode?
    #   Threaded.building?
    #
    # @return [ true, false ] If the thread is in building mode?
    #
    # @since 2.1.0
    def building?
      Thread.current[:"[mongoid]:building-mode"] ||= false
    end

    # Set the building mode for the current thread.
    #
    # @example Set the building mode.
    #   Threaded.building = true
    #
    # @param [ true, false ] mode The current building mode.
    #
    # @return [ true, false ] The current building mode.
    #
    # @since 2.1.0
    def building=(mode)
      Thread.current[:"[mongoid]:building-mode"] = mode
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
    def insert
      Thread.current[:"[mongoid]:insert-consumer"]
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
    def insert=(consumer)
      Thread.current[:"[mongoid]:insert-consumer"] = consumer
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

    # Get the update consumer from the current thread.
    #
    # @example Get the update consumer.
    #   Threaded.update
    #
    # @return [ Object ] The atomic update consumer.
    #
    # @since 2.1.0
    def update
      Thread.current[:"[mongoid]:update-consumer"]
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
    def update=(consumer)
      Thread.current[:"[mongoid]:update-consumer"] = consumer
    end
  end
end
