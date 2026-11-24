# frozen_string_literal: true

module Mongoid
  # Object encapsulating logic for setting/getting a collection and database name
  # and a client with particular options to use when persisting models.
  class PersistenceContext
    extend Forwardable

    # Delegate the cluster method to the client.
    def_delegators :client, :cluster

    # Delegate the storage_options method to the object.
    def_delegators :@object, :storage_options

    # The options defining this persistence context.
    #
    # @return [ Hash ] The persistence context options.
    attr_reader :options

    # Extra options in addition to driver client options that determine the
    # persistence context.
    #
    # @return [ Array<Symbol> ] The list of extra options besides client options
    #   that determine the persistence context.
    EXTRA_OPTIONS = %i[client
                       collection
                       collection_options].freeze

    # The full list of valid persistence context options.
    #
    # @return [ Array<Symbol> ] The full list of options defining the persistence
    #   context.
    VALID_OPTIONS = (Mongo::Client::VALID_OPTIONS + EXTRA_OPTIONS).freeze

    # Initialize the persistence context object.
    #
    # @example Create a new persistence context.
    #   PersistenceContext.new(model, collection: 'other')
    #
    # @param [ Object ] object The class or model instance for which a persistence context
    #   should be created.
    # @param [ Hash ] opts The persistence context options.
    def initialize(object, opts = {})
      @object = object
      set_options!(opts)
    end

    # Returns a new persistence context that is consistent with the given
    # child document, inheriting most appropriate settings.
    #
    # @param [ Mongoid::Document | Class ] document the child document
    #
    # @return [ PersistenceContext ] the new persistence context
    #
    # @api private
    def for_child(document)
      if document.is_a?(Class)
        return self if document == (@object.is_a?(Class) ? @object : @object.class)
      elsif document.is_a?(Mongoid::Document)
        return self if document.class == (@object.is_a?(Class) ? @object : @object.class)
      else
        raise ArgumentError, 'must specify a class or a document instance'
      end

      PersistenceContext.new(document, options.merge(document.storage_options))
    end

    # Get the collection for this persistence context.
    #
    # @example Get the collection for this persistence context.
    #   context.collection
    #
    # @param [ Object ] parent The parent object whose collection name is used
    #   instead of this persistence context's collection name.
    #
    # @return [ Mongo::Collection ] The collection for this persistence
    #   context.
    def collection(parent = nil)
      if parent
        parent.collection.with(client_options.except(:database, 'database'))
      else
        client[collection_name.to_sym]
      end
    end

    # Get the collection name for this persistence context.
    #
    # @example Get the collection name for this persistence context.
    #   context.collection_name
    #
    # @return [ String ] The collection name for this persistence
    #   context.
    def collection_name
      @collection_name ||= __evaluate__(options[:collection] ||
                             storage_options[:collection])
    end

    # Get the database name for this persistence context.
    #
    # @example Get the database name for this persistence context.
    #   context.database_name
    #
    # @return [ String ] The database name for this persistence
    #   context.
    def database_name
      __evaluate__(database_name_option) || client.database.name
    end

    # Get the client for this persistence context.
    #
    # @example Get the client for this persistence context.
    #   context.client
    #
    # @return [ Mongo::Client ] The client for this persistence
    #   context.
    def client
      @client ||= begin
        client = Clients.with_name(client_name)
        options = client_options

        if database_name_option
          client = client.use(database_name)
          options = options.except(:database, 'database')
        end

        client = client.with(options) unless options.empty?

        verify_encryption_schema!(client)

        client
      end
    end

    # Get the client name for this persistence context.
    #
    # @example Get the client name for this persistence context.
    #   context.client_name
    #
    # @return [ Symbol ] The client name for this persistence
    #   context.
    def client_name
      @client_name ||= __evaluate__(options[:client]) ||
                       Threaded.client_override ||
                       __evaluate__(storage_options[:client])
    end

    # Determine if this persistence context is equal to another.
    #
    # @example Compare two persistence contexts.
    #   context == other_context
    #
    # @param [ Object ] other The object to be compared with this one.
    #
    # @return [ true | false ] Whether the two persistence contexts are equal.
    def ==(other)
      return false unless other.is_a?(PersistenceContext)

      options == other.options
    end

    # Whether the client of the context can be reused later, and therefore should
    # not be closed.
    #
    # If the persistence context is requested with :client option only, it means
    # that the context should use a client configured in mongoid.yml.
    # Such clients should not be closed when the context is cleared since they
    # will be reused later.
    #
    # @return [ true | false ] True if client can be reused, otherwise false.
    #
    # @api private
    def reusable_client?
      @options.keys == [ :client ]
    end

    # The subset of provided options that may be used as storage
    # options.
    #
    # @return [ Hash | nil ] the requested storage options, or nil if
    #   none were specified.
    #
    # @api private
    def requested_storage_options
      slice = @options.slice(*Mongoid::Clients::Validators::Storage::VALID_OPTIONS)
      slice.any? ? slice : nil
    end

    private

    def set_options!(opts)
      @options ||= opts.each.reduce({}) do |_options, (key, value)|
        raise Errors::InvalidPersistenceOption.new(key.to_sym, VALID_OPTIONS) unless VALID_OPTIONS.include?(key.to_sym)

        value ? _options.merge!(key => value) : _options
      end
    end

    def __evaluate__(name)
      return nil unless name

      name.respond_to?(:call) ? name.call.to_sym : name.to_sym
    end

    # Refuse to use a client that would store a model's encrypted fields in
    # plaintext.
    #
    # The automatic encryption schema is keyed by namespace and is built once,
    # when the client is created. The driver looks the target namespace up in
    # that schema, and when it is absent it asks the server for a schema
    # instead; a collection without a validator then yields no encryption at
    # all, and no error. Checking the namespace here is what turns that silent
    # downgrade into a failure. When the namespace is present, its entry is
    # checked against the fields the model declares as encrypted too: a
    # hand-written schema can cover the namespace and still leave out a field.
    #
    # @param [ Mongo::Client ] client The client this context resolved to.
    #
    # @raise [ Errors::NoEncryptionSchema ] if the model needs an encryption
    #   schema and the client's schema does not cover the target namespace, or
    #   the namespace entry does not cover every encrypted field of the model.
    def verify_encryption_schema!(client)
      klass = @object.is_a?(Class) ? @object : @object.class
      # A model whose encrypted fields all live on embedded models declares no
      # encryption of its own, and still needs a schema for its collection.
      return unless klass.respond_to?(:requires_encryption_schema?) && klass.requires_encryption_schema?
      # An embedded document is persisted as part of its parent, so the
      # parent's context is what governs the namespace.
      return if klass.embedded?
      # Collection and index management sends no document data, so it does not
      # need an encryption-capable client.
      return if Threaded.managing_collection?

      schema_map = client.options.dig(:auto_encryption_options, :schema_map)
      namespace = "#{client.database.name}.#{collection_name}"
      entry = schema_map && schema_map[namespace]
      raise Errors::NoEncryptionSchema.new(klass, namespace, client_name) unless entry

      # The schema map may have been written by hand, with symbol keys rather
      # than strings; both are tolerated at every level.
      Mongoid.config.encrypted_paths_for(klass).each do |path|
        next if encryption_schema_has_path?(entry, path)

        raise Errors::NoEncryptionSchema.new(
          klass, namespace, client_name, path.join('.')
        )
      end
    end

    # Whether a schema entry encrypts the property at the given path.
    #
    # @param [ Hash ] entry The namespace schema entry.
    # @param [ Array<String> ] path The property path, outermost first.
    #
    # @return [ true | false ] Whether the leaf is marked as encrypted.
    def encryption_schema_has_path?(entry, path)
      node = entry
      path.each do |name|
        properties = schema_value(node, 'properties')
        return false unless properties.is_a?(Hash)

        node = schema_value(properties, name)
        return false unless node.is_a?(Hash)
      end
      !schema_value(node, 'encrypt').nil?
    end

    # Read a schema key that may be written as a string or a symbol.
    #
    # @param [ Hash ] hash The schema object.
    # @param [ String ] key The key to read.
    #
    # @return [ Object ] The value, or nil when the key is absent.
    def schema_value(hash, key)
      return hash[key] if hash.key?(key)

      hash[key.to_sym]
    end

    def client_options
      @client_options ||= begin
        opts = options.select do |k, _v|
          Mongo::Client::VALID_OPTIONS.include?(k.to_sym)
        end
        opts[:read] = { mode: opts[:read] } if opts[:read].is_a?(Symbol)
        opts
      end
    end

    def database_name_option
      @database_name_option ||= options[:database] ||
                                Threaded.database_override ||
                                storage_options[:database]
    end

    class << self
      # Set the persistence context for a particular class or model instance.
      #
      # If there already is a persistence context set, options in the existing
      # context are combined with options given to the set call.
      #
      # @example Set the persistence context for a class or model instance.
      #  PersistenceContext.set(model)
      #
      # @param [ Object ] object The class or model instance.
      # @param [ Hash | Mongoid::PersistenceContext ] options_or_context The persistence
      #   options or a persistence context object.
      #
      # @return [ Mongoid::PersistenceContext ] The persistence context for the object.
      def set(object, options_or_context)
        existing_context = get_context(object)
        existing_options = if existing_context
                             existing_context.options
                           else
                             {}
                           end
        options_or_context = options_or_context.options if options_or_context.is_a?(PersistenceContext)
        new_options = existing_options.merge(options_or_context)
        context = PersistenceContext.new(object, new_options)
        store_context(object, context)
      end

      # Get the persistence context for a particular class or model instance.
      #
      # @example Get the persistence context for a class or model instance.
      #  PersistenceContext.get(model)
      #
      # @param [ Object ] object The class or model instance.
      #
      # @return [ Mongoid::PersistenceContext ] The persistence context for the object.
      def get(object)
        get_context(object)
      end

      # Clear the persistence context for a particular class or model instance.
      #
      # @example Clear the persistence context for a class or model instance.
      #  PersistenceContext.clear(model)
      #
      # @param [ Class | Object ] object The class or model instance.
      # @param [ Mongo::Cluster ] cluster The original cluster before this context was used.
      # @param [ Mongoid::PersistenceContext ] original_context The original persistence
      #   context that was set before this context was used.
      def clear(object, cluster = nil, original_context = nil)
        if (context = get(object)) && !(cluster.nil? || context.cluster.equal?(cluster)) && !context.reusable_client?
          context.client.close
        end
      ensure
        store_context(object, original_context)
      end

      private

      # Key to store persistence contexts in the thread local storage.
      #
      # @api private
      PERSISTENCE_CONTEXT_KEY = :'[mongoid]:persistence_context'

      def context_store
        Threaded.get(PERSISTENCE_CONTEXT_KEY) { {} }
      end

      # Get the persistence context for a given object from the thread local
      #   storage.
      #
      # @param [ Object ] object Object to get the persistence context for.
      #
      # @return [ Mongoid::PersistenceContext | nil ] The persistence context
      #   for the object if previously stored, otherwise nil.
      #
      # @api private
      def get_context(object)
        context_store[object.object_id]
      end

      # Store persistence context for a given object in the thread local
      #   storage.
      #
      # @param [ Object ] object Object to store the persistence context for.
      # @param [ Mongoid::PersistenceContext ] context Context to store
      #
      # @api private
      def store_context(object, context)
        if context.nil?
          context_store.delete(object.object_id)
        else
          context_store[object.object_id] = context
        end
      end
    end
  end
end
