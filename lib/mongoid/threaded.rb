# frozen_string_literal: true

require 'mongoid/threaded/lifecycle'

module Mongoid
  # This module contains logic for easy access to objects that have a lifecycle
  # on the current thread.
  module Threaded
    DATABASE_OVERRIDE_KEY = '[mongoid]:db-override'

    # Constant for the key to store clients.
    CLIENTS_KEY = '[mongoid]:clients'

    # The key to override the client.
    CLIENT_OVERRIDE_KEY = '[mongoid]:client-override'

    # The key for the current thread's scope stack.
    CURRENT_SCOPE_KEY = '[mongoid]:current-scope'

    AUTOSAVES_KEY = '[mongoid]:autosaves'

    VALIDATIONS_KEY = '[mongoid]:validations'

    STACK_KEYS = Hash.new do |hash, key|
      hash[key] = "[mongoid]:#{key}-stack"
    end

    # The key for the current thread's sessions.
    SESSIONS_KEY = '[mongoid]:sessions'

    # The key for storing documents modified inside transactions.
    MODIFIED_DOCUMENTS_KEY = '[mongoid]:modified-documents'

    # The key storing the default value for whether or not callbacks are
    # executed on documents.
    EXECUTE_CALLBACKS = '[mongoid]:execute-callbacks'

    extend self

    # Queries the thread-local variable with the given name. If a block is
    # given, and the variable does not already exist, the return value of the
    # block will be set as the value of the variable before returning it.
    #
    # It is very important that applications (and espcially Mongoid)
    # use this method instead of Thread#[], since Thread#[] is actually for
    # fiber-local variables, and Mongoid uses Fibers as an implementation
    # detail in some callbacks. Putting thread-local state in a fiber-local
    # store will result in the state being invisible when relevant callbacks are
    # run in a different fiber.
    #
    # Affected callbacks are cascading callbacks on embedded children.
    #
    # @param [ String | Symbol ] key the name of the variable to query
    # @param [ Proc ] default an optional block that must return the default
    #   (initial) value of this variable.
    #
    # @return [ Object | nil ] the value of the queried variable, or nil if
    #   it is not set and no default was given.
    def get(key, &default)
      result = Thread.current.thread_variable_get(key)

      if result.nil? && default
        result = yield
        set(key, result)
      end

      result
    end

    # Sets a thread-local variable with the given name to the given value.
    # See #get for a discussion of why this method is necessary, and why
    # Thread#[]= should be avoided in cascading callbacks on embedded children.
    #
    # @param [ String | Symbol ] key the name of the variable to set.
    # @param [ Object | nil ] value the value of the variable to set (or `nil`
    #   if you wish to unset the variable)
    def set(key, value)
      Thread.current.thread_variable_set(key, value)
    end

    # Removes the named variable from thread-local storage.
    #
    # @param [ String | Symbol ] key the name of the variable to remove.
    def delete(key)
      set(key, nil)
    end

    # Queries the presence of a named variable in thread-local storage.
    #
    # @param [ String | Symbol ] key the name of the variable to query.
    #
    # @return [ true | false ] whether the given variable is present or not.
    def has?(key)
      # Here we have a classic example of JRuby not behaving like MRI. In
      # MRI, if you set a thread variable to nil, it removes it from the list
      # and subsequent calls to thread_variable?(key) will return false. Not
      # so with JRuby. Once set, you cannot unset the thread variable.
      #
      # However, because setting a variable to nil is supposed to remove it,
      # we can assume a nil-valued variable doesn't actually exist.

      # So, instead of this:
      # Thread.current.thread_variable?(key)

      # We have to do this:
      !get(key).nil?
    end

    # Begin entry into a named thread local stack.
    #
    # @example Begin entry into the stack.
    #   Threaded.begin_execution(:create)
    #
    # @param [ String ] name The name of the stack
    #
    # @return [ true ] True.
    def begin_execution(name)
      stack(name).push(true)
    end

    # Get the global database override.
    #
    # @example Get the global database override.
    #   Threaded.database_override
    #
    # @return [ String | Symbol ] The override.
    def database_override
      get(DATABASE_OVERRIDE_KEY)
    end

    # Set the global database override.
    #
    # @example Set the global database override.
    #   Threaded.database_override = :testing
    #
    # @param [ String | Symbol ] name The global override name.
    #
    # @return [ String | Symbol ] The override.
    def database_override=(name)
      set(DATABASE_OVERRIDE_KEY, name)
    end

    # Are in the middle of executing the named stack
    #
    # @example Are we in the stack execution?
    #   Threaded.executing?(:create)
    #
    # @param [ Symbol ] name The name of the stack
    #
    # @return [ true ] If the stack is being executed.
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
    def stack(name)
      get(STACK_KEYS[name]) { [] }
    end

    # Begin autosaving a document on the current thread.
    #
    # @example Begin autosave.
    #   Threaded.begin_autosave(doc)
    #
    # @param [ Document ] document The document to autosave.
    def begin_autosave(document)
      autosaves_for(document.class).push(document._id)
    end

    # Begin validating a document on the current thread.
    #
    # @example Begin validation.
    #   Threaded.begin_validate(doc)
    #
    # @param [ Document ] document The document to validate.
    def begin_validate(document)
      validations_for(document.class).push(document._id)
    end

    # Exit autosaving a document on the current thread.
    #
    # @example Exit autosave.
    #   Threaded.exit_autosave(doc)
    #
    # @param [ Document ] document The document to autosave.
    def exit_autosave(document)
      autosaves_for(document.class).delete_one(document._id)
    end

    # Exit validating a document on the current thread.
    #
    # @example Exit validation.
    #   Threaded.exit_validate(doc)
    #
    # @param [ Document ] document The document to validate.
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
    # @return [ String | Symbol ] The override.
    def client_override
      get(CLIENT_OVERRIDE_KEY)
    end

    # Set the global client override.
    #
    # @example Set the global client override.
    #   Threaded.client_override = :testing
    #
    # @param [ String | Symbol ] name The global override name.
    #
    # @return [ String | Symbol ] The override.
    def client_override=(name)
      set(CLIENT_OVERRIDE_KEY, name)
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
    def current_scope(klass = nil)
      current_scope = get(CURRENT_SCOPE_KEY)

      if klass && current_scope.respond_to?(:keys)
        current_scope[current_scope.keys.find { |k| k <= klass }]
      else
        current_scope
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
    def current_scope=(scope)
      set(CURRENT_SCOPE_KEY, scope)
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
    def set_current_scope(scope, klass)
      if scope.nil?
        unset_current_scope(klass)
      else
        current_scope = get(CURRENT_SCOPE_KEY) { {} }
        current_scope[klass] = scope
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
    # @return [ true | false ] If the document is autosaved.
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
    # @return [ true | false ] If the document is validated.
    def validated?(document)
      validations_for(document.class).include?(document._id)
    end

    # Get all autosaves on the current thread.
    #
    # @example Get all autosaves.
    #   Threaded.autosaves
    #
    # @return [ Hash ] The current autosaves.
    def autosaves
      get(AUTOSAVES_KEY) { {} }
    end

    # Get all validations on the current thread.
    #
    # @example Get all validations.
    #   Threaded.validations
    #
    # @return [ Hash ] The current validations.
    def validations
      get(VALIDATIONS_KEY) { {} }
    end

    # Get all autosaves on the current thread for the class.
    #
    # @example Get all autosaves.
    #   Threaded.autosaves_for(Person)
    #
    # @param [ Class ] klass The class to check.
    #
    # @return [ Array ] The current autosaves.
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
    def validations_for(klass)
      validations[klass] ||= []
    end

    # Cache a session for this thread for a client.
    #
    # @note For backward compatibility it is allowed to call this method without
    # specifying `client` parameter.
    #
    # @param [ Mongo::Session ] session The session to save.
    # @param [ Mongo::Client | nil ] client The client to cache the session for.
    def set_session(session, client: nil)
      sessions[client] = session
    end

    # Get the cached session for this thread for a client.
    #
    # @note For backward compatibility it is allowed to call this method without
    # specifying `client` parameter.
    #
    # @param [ Mongo::Client | nil ] client The client to cache the session for.
    #
    # @return [ Mongo::Session | nil ] The session cached on this thread or nil.
    def get_session(client: nil)
      sessions[client]
    end

    # Clear the cached session for this thread for a client.
    #
    # @note For backward compatibility it is allowed to call this method without
    # specifying `client` parameter.
    #
    # @param [ Mongo::Client | nil ] client The client to clear the session for.
    #
    # @return [ nil ]
    def clear_session(client: nil)
      sessions.delete(client)&.end_session
    end

    # Store a reference to the document that was modified inside a transaction
    # associated with the session.
    #
    # @param [ Mongo::Session ] session Session in scope of which the document
    #   was modified.
    # @param [ Mongoid::Document ] document Mongoid document that was modified.
    def add_modified_document(session, document)
      return unless session&.in_transaction?

      modified_documents[session] << document
    end

    # Clears the set of modified documents for the given session, and return the
    # content of the set before the clearance.
    # @param [ Mongo::Session ] session Session for which the modified documents
    #   set should be cleared.
    #
    # @return [ Set<Mongoid::Document> ] Collection of modified documents before
    #   it was cleared.
    def clear_modified_documents(session)
      modified_documents.delete(session) || []
    end

    # Queries whether document callbacks should be executed by default for the
    # current thread.
    #
    # Unless otherwise indicated (by #execute_callbacks=), this will return
    # true.
    #
    # @return [ true | false ] Whether or not document callbacks should be
    #   executed by default.
    def execute_callbacks?
      if has?(EXECUTE_CALLBACKS)
        get(EXECUTE_CALLBACKS)
      else
        true
      end
    end

    # Indicates whether document callbacks should be invoked by default for
    # the current thread. Individual documents may further override the
    # callback behavior, but this will be used for the default behavior.
    #
    # @param flag [ true | false ] Whether or not document callbacks should be
    #   executed by default.
    def execute_callbacks=(flag)
      set(EXECUTE_CALLBACKS, flag)
    end

    # Returns the thread store of sessions.
    #
    # @return [ Hash<Integer, Set> ] The sessions indexed by client object ID.
    #
    # @api private
    def sessions
      get(SESSIONS_KEY) { {}.compare_by_identity }
    end

    # Returns the thread store of modified documents.
    #
    # @return [ Hash<Mongo::Session, Set<Mongoid::Document>> ] The modified
    #   documents indexed by session.
    #
    # @api private
    def modified_documents
      get(MODIFIED_DOCUMENTS_KEY) { Hash.new { |h, k| h[k] = Set.new } }
    end

    private

    # Removes the given klass from the current scope, and tidies the current
    # scope list.
    #
    # @param klass [ Class ] the class to remove from the current scope.
    def unset_current_scope(klass)
      return unless has?(CURRENT_SCOPE_KEY)

      scope = get(CURRENT_SCOPE_KEY)
      scope.delete(klass)

      delete(CURRENT_SCOPE_KEY) if scope.empty?
    end
  end
end
