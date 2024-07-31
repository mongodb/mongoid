# frozen_string_literal: true

require 'forwardable'

module Mongoid
  # The default class for resolving model classes based on discriminant keys.
  # Given a key, it will return the corresponding model class, if any. By
  # default, it looks for classes with names that match the given keys, but
  # additional mappings may be provided.
  #
  # It is also possible to instantiate multiple resolvers---and even implement
  # your own---so that different sets of classes can use independent resolution
  # mechanics.
  class ModelResolver
    # The mutex instance used to make the `.instance` method thread-safe.
    #
    # @api private
    INSTANCE_MUTEX = Mutex.new

    class << self
      extend Forwardable
      def_delegators :instance, :register

      # Returns the default instance of the ModelResolver.
      #
      # @return [ Mongoid::ModelResolver ] the default ModelResolver instance.
      def instance
        @instance ||= INSTANCE_MUTEX.synchronize { @instance ||= new }
      end

      # Returns the map of registered resolvers. The default resolver is not
      # included here.
      #
      # @return [ Hash<Symbol => Mongoid::ModelResolver::Interface> ] the hash of
      #   resolver instances, mapped by symbol identifier.
      def resolvers
        @resolvers ||= {}
      end

      # Returns the resolver instance that corresponds to the argument.
      #
      # @param [ nil | true | false Symbol | String | Mongoid::ModelResolver::Interface ] identifier_or_object
      #   When nil or false, returns nil. When true or :default, corresponds to the default resolver.
      #   When any other symbol or string, corresponds to the registered resolver with that identifier.
      #   Otherwise, it must be a resolver instance itself.
      #
      # @raise Mongoid::Errors::UnrecognizedResolver if the given identifier is a
      #   symbol or string and it does not match any registered resolver.
      #
      # @return [ Mongoid::ModelResolver::Interface ] the resolver instance corresponding to the
      #   given argument.
      def resolver(identifier_or_object = :default)
        case identifier_or_object
        when nil, false then nil
        when true, :default then instance
        when String, Symbol
          resolvers.fetch(identifier_or_object.to_sym) do |key|
            raise Mongoid::Errors::UnrecognizedResolver, key
          end
        else identifier_or_object
        end
      end

      # Register the given resolver under the given name.
      #
      # @param [ Mongoid::ModelResolver::Interface ] resolver the resolver to register.
      # @param [ String | Symbol ] name the identifier to use to register the resolver.
      def register_resolver(resolver, name)
        resolvers[name.to_sym] = resolver
        self
      end
    end

    # Instantiates a new ModelResolver instance.
    def initialize
      @key_to_model = {}
      @model_to_keys = {}
    end

    # Registers the given model class with the given keys. In addition to the given keys, the
    # class name itself will be included as a key to identify the class. Keys are given in priority
    # order, with highest priority keys first and lowest last. The class name, if not given explicitly,
    # is always given lowest priority.
    #
    # If called more than once, newer keys have higher priority than older keys. All duplicate keys will
    # be removed.
    #
    # @param [ Mongoid::Document ] klass the document class to register
    # @param [ Array<String> ] *keys the list of keys to use as an alias (optional)
    def register(klass, *keys)
      default_key = klass.name

      @model_to_keys[klass] = [ *keys, *@model_to_keys[klass], default_key ].uniq
      @key_to_model[default_key] = klass

      keys.each do |key|
        @key_to_model[key] = klass
      end

      self
    end

    # The `Interface` concern represents the interface that custom resolvers
    # must implement.
    concerning :Interface do
      # Returns the default (highest priority) key for the given record. This is typically
      # the key that will be used when saving a new polymorphic association.
      #
      # @param [ Mongoid::Document ] record the record instance for which to query the default key.
      #
      # @raise Mongoid::Errors::UnregisteredClass if the record's class has not been registered with this resolver.
      #
      # @return [ String ] the default key for the record's class.
      def default_key_for(record)
        keys_for(record).first
      end

      # Returns the list of all keys for the given record's class, in priority order (with highest
      # priority keys first).
      #
      # @param [ Mongoid::Document] record the record instance for which to query the registered keys.
      #
      # @raise Mongoid::Errors::UnregisteredClass if the record's class has not been registered with this resolver.
      #
      # @return [ Array<String> ] the list of keys that have been registered for the given class.
      def keys_for(record)
        @model_to_keys.fetch(record.class) do |klass|
          # figure out which resolver this is
          resolver = if self == Mongoid::ModelResolver.instance
                       :default
                     else
                       Mongoid::ModelResolver.resolvers.keys.detect { |k| Mongoid::ModelResolver.resolvers[k] == self }
                     end
          resolver ||= self # if it hasn't been registered, we'll show it the best we can
          raise Mongoid::Errors::UnregisteredClass.new(klass, resolver)
        end
      end

      # Returns the document class that has been registered by the given key.
      #
      # @param [ String ] key the key by which to query the corresponding class.
      #
      # @raise Mongoid::Errors::UnrecognizedModelAlias if the given key has not
      #   been registered with this resolver.
      #
      # @return [ Class ] the document class that has been registered with the given key.
      def model_for(key)
        @key_to_model.fetch(key) do
          raise Mongoid::Errors::UnrecognizedModelAlias, key
        end
      end
    end
  end
end
