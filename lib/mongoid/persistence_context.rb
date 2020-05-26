# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # Object encapsulating logic for setting/getting a collection and database name
  # and a client with particular options to use when persisting models.
  #
  # @since 6.0.0
  class PersistenceContext
    extend Forwardable

    # Delegate the cluster method to the client.
    def_delegators :client, :cluster

    # Delegate the storage options method to the object.
    def_delegators :@object, :storage_options

    # The options defining this persistence context.
    #
    # @return [ Hash ] The persistence context options.
    #
    # @since 6.0.0
    attr_reader :options

    # Extra options in addition to driver client options that determine the
    # persistence context.
    #
    # @return [ Array<Symbol> ] The list of extra options besides client options
    #   that determine the persistence context.
    #
    # @since 6.0.0
    EXTRA_OPTIONS = [ :client,
                      :collection
                    ].freeze

    # The full list of valid persistence context options.
    #
    # @return [ Array<Symbol> ] The full list of options defining the persistence
    #   context.
    #
    # @since 6.0.0
    VALID_OPTIONS = ( Mongo::Client::VALID_OPTIONS + EXTRA_OPTIONS ).freeze

    # Initialize the persistence context object.
    #
    # @example Create a new persistence context.
    #   PersistenceContext.new(model, collection: 'other')
    #
    # @param [ Object ] object The class or model instance for which a persistence context
    #   should be created.
    # @param [ Hash ] opts The persistence context options.
    #
    # @since 6.0.0
    def initialize(object, opts = {})
      @object = object
      set_options!(opts)
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
    #
    # @since 6.0.0
    def collection(parent = nil)
      parent ? parent.collection.with(client_options) : client[collection_name.to_sym]
    end

    # Get the collection name for this persistence context.
    #
    # @example Get the collection name for this persistence context.
    #   context.collection_name
    #
    # @return [ String ] The collection name for this persistence
    #  context.
    #
    # @since 6.0.0
    def collection_name
      @collection_name ||= (__evaluate__(options[:collection] ||
                             storage_options[:collection]))
    end

    # Get the database name for this persistence context.
    #
    # @example Get the database name for this persistence context.
    #   context.database_name
    #
    # @return [ String ] The database name for this persistence
    #  context.
    #
    # @since 6.0.0
    def database_name
      __evaluate__(database_name_option) || client.database.name
    end

    # Get the client for this persistence context.
    #
    # @example Get the client for this persistence context.
    #   context.client
    #
    # @return [ Mongo::Client ] The client for this persistence
    #  context.
    #
    # @since 6.0.0
    def client
      @client ||= begin
        client = Clients.with_name(client_name)
        if database_name_option
          client = client.use(database_name)
        end
        unless client_options.empty?
          client = client.with(client_options)
        end
        client
      end
    end

    def client_name
      @client_name ||= options[:client] ||
                         Threaded.client_override ||
                         storage_options && __evaluate__(storage_options[:client])
    end

    # Determine if this persistence context is equal to another.
    #
    # @example Compare two persistence contexts.
    #   context == other_context
    #
    # @param [ Object ] other The object to be compared with this one.
    #
    # @return [ true, false ] Whether the two persistence contexts are equal.
    #
    # @since 6.0.0
    def ==(other)
      return false unless other.is_a?(PersistenceContext)
      options == other.options
    end

    private

    def set_options!(opts)
      @options ||= opts.each.reduce({}) do |_options, (key, value)|
                     unless VALID_OPTIONS.include?(key.to_sym)
                       raise Errors::InvalidPersistenceOption.new(key.to_sym, VALID_OPTIONS)
                     end
                     value ? _options.merge!(key => value) : _options
                   end
    end

    def __evaluate__(name)
      return nil unless name
      name.respond_to?(:call) ? name.call.to_sym : name.to_sym
    end

    def client_options
      @client_options ||= begin
        opts = options.select do |k, v|
                              Mongo::Client::VALID_OPTIONS.include?(k.to_sym)
                            end
        if opts[:read].is_a?(Symbol)
          opts[:read] = {mode: opts[:read]}
        end
        opts
      end
    end

    def database_name_option
      @database_name_option ||= options[:database] ||
                                  Threaded.database_override ||
                                  storage_options && storage_options[:database]
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
      # @param [ Hash, Mongoid::PersistenceContext ] options_or_context The persistence
      #   options or a persistence context object.
      #
      # @return [ Mongoid::PersistenceContext ] The persistence context for the object.
      #
      # @since 6.0.0
      def set(object, options_or_context)
        key = "[mongoid][#{object.object_id}]:context"
        existing_context = Thread.current[key]
        existing_options = if existing_context
          existing_context.options
        else
          {}
        end
        if options_or_context.is_a?(PersistenceContext)
          options_or_context = options_or_context.options
        end
        new_options = existing_options.merge(options_or_context)
        context = PersistenceContext.new(object, new_options)
        Thread.current[key] = context
      end

      # Get the persistence context for a particular class or model instance.
      #
      # @example Get the persistence context for a class or model instance.
      #  PersistenceContext.get(model)
      #
      # @param [ Object ] object The class or model instance.
      #
      # @return [ Mongoid::PersistenceContext ] The persistence context for the object.
      #
      # @since 6.0.0
      def get(object)
        Thread.current["[mongoid][#{object.object_id}]:context"]
      end

      # Clear the persistence context for a particular class or model instance.
      #
      # @example Clear the persistence context for a class or model instance.
      #  PersistenceContext.clear(model)
      #
      # @param [ Class, Object ] object The class or model instance.
      # @param [ Mongo::Cluster ] cluster The original cluster before this context was used.
      # @param [ Mongoid::PersistenceContext ] original_context The original persistence
      #   context that was set before this context was used.
      #
      # @since 6.0.0
      def clear(object, cluster = nil, original_context = nil)
        if context = get(object)
          context.client.close unless (context.cluster.equal?(cluster) || cluster.nil?)
        end
      ensure
        Thread.current["[mongoid][#{object.object_id}]:context"] = original_context
      end
    end
  end
end
