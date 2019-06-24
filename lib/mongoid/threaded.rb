# frozen_string_literal: true
# encoding: utf-8

require "mongoid/threaded/lifecycle"

module Mongoid

  # This module contains logic for easy access to objects that have a lifecycle
  # on the current thread.
  module Threaded

    DATABASE_OVERRIDE_KEY = "[mongoid]:db-override"

    # Constant for the key to store clients.
    #
    # @since 5.0.0
    CLIENTS_KEY = "[mongoid]:clients"

    # The key to override the client.
    #
    # @since 5.0.0
    CLIENT_OVERRIDE_KEY = "[mongoid]:client-override"

    # The key for the current thread's scope stack.
    #
    # @since 2.0.0
    CURRENT_SCOPE_KEY = "[mongoid]:current-scope"

    AUTOSAVES_KEY = "[mongoid]:autosaves"
    VALIDATIONS_KEY = "[mongoid]:validations"

    STACK_KEYS = Hash.new do |hash, key|
      hash[key] = "[mongoid]:#{key}-stack"
    end

    extend self

    # Begin entry into a named thread local stack.
    #
    # @example Begin entry into the stack.
    #   Threaded.begin_execution(:create)
    #
    # @param [ String ] name The name of the stack
    #
    # @return [ true ] True.
    #
    # @since 2.4.0
    def begin_execution(name)
      stack(name).push(true)
    end

    # Get the global database override.
    #
    # @example Get the global database override.
    #   Threaded.database_override
    #
    # @return [ String, Symbol ] The override.
    #
    # @since 3.0.0
    def database_override
      Thread.current[DATABASE_OVERRIDE_KEY]
    end

    # Set the global database override.
    #
    # @example Set the global database override.
    #   Threaded.database_override = :testing
    #
    # @param [ String, Symbol ] name The global override name.
    #
    # @return [ String, Symbol ] The override.
    #
    # @since 3.0.0
    def database_override=(name)
      Thread.current[DATABASE_OVERRIDE_KEY] = name
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
    #   Threaded.exit_execution(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ true ] True.
    #
    # @since 2.4.0
    def exit_execution(name)
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
      Thread.current[STACK_KEYS[name]] ||= []
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
      autosaves_for(document.class).push(document._id)
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
      validations_for(document.class).push(document._id)
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
      autosaves_for(document.class).delete_one(document._id)
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
      validations_for(document.class).delete_one(document._id)
    end

    # Begin suppressing default scopes for given model on the current thread.
    #
    # @example Begin without default scope stack.
    #   Threaded.begin_without_default_scope(klass)
    #
    # @param [ Class ] klass The model to suppress default scoping on.
    #
    # @api private
    def begin_without_default_scope(klass)
      stack(:without_default_scope).push(klass)
    end

    # Exit suppressing default scopes for given model on the current thread.
    #
    # @example Exit without default scope stack.
    #   Threaded.exit_without_default_scope(klass)
    #
    # @param [ Class ] klass The model to unsuppress default scoping on.
    #
    # @api private
    def exit_without_default_scope(klass)
      stack(:without_default_scope).delete(klass)
    end

    # Get the global client override.
    #
    # @example Get the global client override.
    #   Threaded.client_override
    #
    # @return [ String, Symbol ] The override.
    #
    # @since 5.0.0
    def client_override
      Thread.current[CLIENT_OVERRIDE_KEY]
    end

    # Set the global client override.
    #
    # @example Set the global client override.
    #   Threaded.client_override = :testing
    #
    # @param [ String, Symbol ] name The global override name.
    #
    # @return [ String, Symbol ] The override.
    #
    # @since 3.0.0
    def client_override=(name)
      Thread.current[CLIENT_OVERRIDE_KEY] = name
    end

    # Get the current Mongoid scope.
    #
    # @example Get the scope.
    #   Threaded.current_scope(klass)
    #   Threaded.current_scope
    #
    # @param [ Klass ] klass The class type of the scope.
    #
    # @return [ Criteria ] The scope.
    #
    # @since 5.0.0
    def current_scope(klass = nil)
      if klass && Thread.current[CURRENT_SCOPE_KEY].respond_to?(:keys)
        Thread.current[CURRENT_SCOPE_KEY][
            Thread.current[CURRENT_SCOPE_KEY].keys.find { |k| k <= klass }
        ]
      else
        Thread.current[CURRENT_SCOPE_KEY]
      end
    end

    # Set the current Mongoid scope.
    #
    # @example Set the scope.
    #   Threaded.current_scope = scope
    #
    # @param [ Criteria ] scope The current scope.
    #
    # @return [ Criteria ] The scope.
    #
    # @since 5.0.0
    def current_scope=(scope)
      Thread.current[CURRENT_SCOPE_KEY] = scope
    end

    # Set the current Mongoid scope. Safe for multi-model scope chaining.
    #
    # @example Set the scope.
    #   Threaded.current_scope(scope, klass)
    #
    # @param [ Criteria ] scope The current scope.
    # @param [ Class ] klass The current model class.
    #
    # @return [ Criteria ] The scope.
    #
    # @since 5.0.1
    def set_current_scope(scope, klass)
      if scope.nil?
        if Thread.current[CURRENT_SCOPE_KEY]
          Thread.current[CURRENT_SCOPE_KEY].delete(klass)
          Thread.current[CURRENT_SCOPE_KEY] = nil if Thread.current[CURRENT_SCOPE_KEY].empty?
        end
      else
        Thread.current[CURRENT_SCOPE_KEY] ||= {}
        Thread.current[CURRENT_SCOPE_KEY][klass] = scope
      end
    end

    # Is the given klass' default scope suppressed on the current thread?
    #
    # @example Is the given klass' default scope suppressed?
    #   Threaded.without_default_scope?(klass)
    #
    # @param [ Class ] klass The model to check for default scope suppression.
    #
    # @api private
    def without_default_scope?(klass)
      stack(:without_default_scope).include?(klass)
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
      autosaves_for(document.class).include?(document._id)
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
      validations_for(document.class).include?(document._id)
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
      Thread.current[AUTOSAVES_KEY] ||= {}
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
      Thread.current[VALIDATIONS_KEY] ||= {}
    end

    # Get all autosaves on the current thread for the class.
    #
    # @example Get all autosaves.
    #   Threaded.autosaves_for(Person)
    #
    # @param [ Class ] klass The class to check.
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
    # @param [ Class ] klass The class to check.
    #
    # @return [ Array ] The current validations.
    #
    # @since 2.1.9
    def validations_for(klass)
      validations[klass] ||= []
    end

    # Cache a session for this thread.
    #
    # @example Save a session for this thread.
    #   Threaded.set_session(session)
    #
    # @param [ Mongo::Session ] session The session to save.
    #
    # @since 6.4.0
    def set_session(session)
      Thread.current[:session] = session
    end

    # Get the cached session for this thread.
    #
    # @example Get the session for this thread.
    #   Threaded.get_session
    #
    # @return [ Mongo::Session, nil ] The session cached on this thread or nil.
    #
    # @since 6.4.0
    def get_session
      Thread.current[:session]
    end

    # Clear the cached session for this thread.
    #
    # @example Clear this thread's session.
    #   Threaded.clear_session
    #
    # @return [ nil ]
    #
    # @since 6.4.0
    def clear_session
      session = get_session
      session.end_session if session
      Thread.current[:session] = nil
    end
  end
end
