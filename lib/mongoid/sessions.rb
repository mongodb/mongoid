# encoding: utf-8
require "mongoid/sessions/factory"
require "mongoid/sessions/validators"

module Mongoid #:nodoc:
  module Sessions
    extend ActiveSupport::Concern

    included do
      cattr_accessor :default_collection_name, :storage_options
      self.default_collection_name = self.name.collectionize.to_sym
    end

    # Get the collection for this model from the session. Will check for an
    # overridden collection name from the store_in macro or the collection
    # with a pluralized model name.
    #
    # @example Get the model's collection.
    #   Model.collection
    #
    # @return [ Moped::Collection ] The collection.
    #
    # @since 3.0.0
    def collection
      self.class.collection
    end

    # Get the name of the collection this model persists to. This will be
    # either the pluralized class name or the option defined in the store_in
    # macro.
    #
    # @example Get the collection name.
    #   Model.collection_name
    #
    # @return [ String ] The name of the collection.
    #
    # @since 3.0.0
    def collection_name
      self.class.collection_name
    end

    # Get the session for this model. This is determined in the following order:
    #
    #   1. Any custom configuration provided by the 'store_in' macro.
    #   2. The 'default' session as provided in the mongoid.yml
    #
    # @example Get the session.
    #   model.mongo_session
    #
    # @return [ Moped::Session ] The default moped session.
    #
    # @since 3.0.0
    def mongo_session
      self.class.mongo_session
    end

    # Tell the next persistance operation to store in a specific collection,
    # database or session.
    #
    # @example Save the current document to a different collection.
    #   model.with(collection: "secondary").save
    #
    # @example Save the current document to a different database.
    #   model.with(database: "secondary").save
    #
    # @example Save the current document to a different session.
    #   model.with(session: "replica_set").save
    #
    # @example Save with a combination of options.
    #   model.with(session: "sharded", database: "secondary").save
    #
    # @param [ Hash ] options The storage options.
    #
    # @option options [ String, Symbol ] :collection The collection name.
    # @option options [ String, Symbol ] :database The database name.
    # @option options [ String, Symbol ] :session The session name.
    #
    # @return [ Document ] The current document.
    #
    # @since 3.0.0
    def with(options)
      tap do
        Threaded.set_persistence_options(self.class, options)
      end
    end

    class << self

      # Get the default session.
      #
      # @example Get the default session.
      #   Mongoid::Sessions.default
      #
      # @return [ Moped::Session ] The default session.
      #
      # @since 3.0.0
      def default
        Threaded.sessions[:default] ||= Sessions::Factory.default
      end

      # Get a session with the provided name.
      #
      # @example Get a session with the name.
      #   Mongoid::Sessions.with_name(:replica)
      #
      # @param [ Symbol ] name The name of the session.
      #
      # @return [ Moped::Session ] The named session.
      #
      # @since 3.0.0
      def with_name(name)
        Threaded.sessions[name.to_sym] ||= Sessions::Factory.create(name)
      end
    end

    module ClassMethods

      # Clear all persistence options from the current thread.
      #
      # @example Clear the persistence options.
      #   Mongoid::Sessions.clear_persistence_options
      #
      # @return [ true ] True.
      #
      # @since 3.0.0
      def clear_persistence_options
        Threaded.clear_persistence_options(self)
      end

      # Get the collection for this model from the session. Will check for an
      # overridden collection name from the store_in macro or the collection
      # with a pluralized model name.
      #
      # @example Get the model's collection.
      #   Model.collection
      #
      # @return [ Moped::Collection ] The collection.
      #
      # @since 3.0.0
      def collection
        if opts = persistence_options
          mongo_session.with(opts)[opts[:collection] || collection_name].tap do
            clear_persistence_options
          end
        else
          mongo_session[collection_name]
        end
      end

      # Get the name of the collection this model persists to. This will be
      # either the pluralized class name or the option defined in the store_in
      # macro.
      #
      # @example Get the collection name.
      #   Model.collection_name
      #
      # @return [ String ] The name of the collection.
      #
      # @since 3.0.0
      def collection_name
        @collection_name ||= __collection_name__
      end

      # Get the session for this model. This is determined in the following order:
      #
      #   1. Any custom configuration provided by the 'store_in' macro.
      #   2. The 'default' session as provided in the mongoid.yml
      #
      # @example Get the session.
      #   Model.mongo_session
      #
      # @return [ Moped::Session ] The default moped session.
      #
      # @since 3.0.0
      def mongo_session
        __session__.tap do |session|
          if storage_options && name = storage_options[:database]
            session.use(name)
          end
        end
      end

      # Get the persistence options from the current thread.
      #
      # @example Get the persistence options.
      #   Model.persistence_options
      #
      # @return [ Hash ] The persistence options.
      #
      # @since 3.0.0
      def persistence_options
        Threaded.persistence_options(self)
      end

      # Give this model specific custom default storage options.
      #
      # @example Store this model by default in "artists"
      #   class Band
      #     include Mongoid::Document
      #     store_in collection: "artists"
      #   end
      #
      # @example Store this model by default in the sharded db.
      #   class Band
      #     include Mongoid::Document
      #     store_in database: "echo_shard"
      #   end
      #
      # @example Store this model by default in a different session.
      #   class Band
      #     include Mongoid::Document
      #     store_in session: "secondary"
      #   end
      #
      # @example Store this model with a combination of options.
      #   class Band
      #     include Mongoid::Document
      #     store_in collection: "artists", database: "secondary"
      #   end
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :session The session name.
      #
      # @return [ Class ] The model class.
      #
      # @since 3.0.0
      def store_in(options)
        Validators::Storage.validate(self, options)
        self.storage_options = options
      end

      # Tell the next persistance operation to store in a specific collection,
      # database or session.
      #
      # @example Create a document in a different collection.
      #   Model.with(collection: "secondary").create(name: "test")
      #
      # @example Create a document in a different database.
      #   Model.with(database: "secondary").create(name: "test")
      #
      # @example Create a document in a different session.
      #   Model.with(session: "secondary").create(name: "test")
      #
      # @example Create with a combination of options.
      #   Model.with(session: "sharded", database: "secondary").create
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :session The session name.
      #
      # @return [ Class ] The model class.
      #
      # @since 3.0.0
      def with(options)
        tap do
          Threaded.set_persistence_options(self, options)
        end
      end

      private

      # Get the name of the collection this model persists to.
      #
      # @example Get the collection name.
      #   Model.__collection_name__
      #
      # @return [ String ] The name of the collection.
      #
      # @since 3.0.0
      def __collection_name__
        if storage_options && name = storage_options[:collection]
          name.to_sym
        else
          default_collection_name
        end
      end

      # Get the session for this class.
      #
      # @example Get the session.
      #   Model.__session__
      #
      # @return [ Moped::Session ] The moped session.
      #
      # @since 3.0.0
      def __session__
        if persistence_options && name = persistence_options[:session]
          Sessions.with_name(name)
        elsif storage_options && name = storage_options[:session]
          Sessions.with_name(name)
        else
          Sessions.default
        end
      end
    end
  end
end
