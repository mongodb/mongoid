# encoding: utf-8
require "mongoid/sessions/factory"
require "mongoid/sessions/validators"
require "mongoid/sessions/options"

module Mongoid
  module Sessions
    extend ActiveSupport::Concern
    include Options

    included do
      cattr_accessor :default_collection_name do
        self.name.collectionize.to_sym
      end

      cattr_accessor :storage_options, instance_writer: false do
        {}
      end
    end

    class << self

      # Clear all sessions from the current thread.
      #
      # @example Clear all sessions.
      #   Mongoid::Sessions.clear
      #
      # @return [ Array ] The empty sessions.
      #
      # @since 3.0.0
      def clear
        Threaded.sessions.clear
      end

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

      # Disconnect all active sessions.
      #
      # @example Disconnect all active sessions.
      #   Mongoid::Sessions.disconnect
      #
      # @return [ true ] True.
      #
      # @since 3.1.0
      def disconnect
        Threaded.sessions.values.each do |session|
          session.disconnect
        end
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
      mongo_session[collection_name]
    end

    def mongo_session
      persistence_options ? self.class.mongo_session.with(persistence_options) : self.class.mongo_session
    end

    def collection_name
      persistence_options.try { |opts| opts[:collection] } || self.class.collection_name
    end

    module ClassMethods

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
        mongo_session[collection_name]
      end

      # Get the name of the collection this model persists to. This will be
      # either the pluralized class name or the option defined in the store_in
      # macro.
      #
      # @example Get the collection name.
      #   Model.collection_name
      #
      # @return [ Symbol ] The name of the collection.
      #
      # @since 3.0.0
      def collection_name
        __collection_name__
      end

      # Get the default database name for this model.
      #
      # @example Get the default database name.
      #   Model.database_name
      #
      # @return [ Symbol ] The name of the database.
      #
      # @since 3.0.0
      def database_name
        __database_name__
      end

      # Get the overridden database name. This either can be overridden by
      # using +Model.with+ or by overriding at the global level via
      # +Mongoid.override_database(:name)+.
      #
      # @example Get the overridden database name.
      #   Model.database_override
      #
      # @return [ String, Symbol ] The overridden database name.
      #
      # @since 3.0.0
      def database_override
        self.persistence_options.try { |opts| opts[:database] } || Threaded.database_override
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
        session = __session__
        session.use(database_override || current_database_name(session))
        self.persistence_options ? session.with(self.persistence_options) : session
      end

      # Get the overridden session name. This either can be overridden by
      # using +Model.with+ or by overriding at the global level via
      # +Mongoid.override_session(:name)+.
      #
      # @example Get the overridden session name.
      #   Model.session_override
      #
      # @return [ String, Symbol ] The overridden session name.
      #
      # @since 3.0.0
      def session_override
        self.persistence_options.try { |opts| opts[:session] } || Threaded.session_override
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
        storage_options.merge!(options)
      end

      private

      # Get the name of the collection this model persists to.
      #
      # @example Get the collection name.
      #   Model.__collection_name__
      #
      # @return [ Symbol ] The name of the collection.
      #
      # @since 3.0.0
      def __collection_name__
        if coll = self.persistence_options.try(:[], :collection)
          return coll
        end

        if storage_options && name = storage_options[:collection]
          __evaluate__(name)
        else
          default_collection_name
        end
      end

      # Get the database name for the model.
      #
      # @example Get the database name.
      #   Model.__database_name__
      #
      # @return [ Symbol ] The name of the database.
      #
      # @since 3.0.0
      def __database_name__
        if storage_options && name = storage_options[:database]
          __evaluate__(name)
        else
          Mongoid.sessions[__session_name__][:database]
        end
      end

      # Get the session name for the model.
      #
      # @example Get the session name.
      #   Model.__session_name__
      #
      # @return [ Symbol ] The name of the session.
      #
      # @since 3.0.0
      def __session_name__
        if storage_options && name = storage_options[:session]
          __evaluate__(name)
        else
          :default
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
        if !(name = session_override).nil?
          Sessions.with_name(name)
        else
          Sessions.with_name(__session_name__)
        end
      end

      # Eval the provided value, either byt calling it if it responds to call
      # or returning the value itself.
      #
      # @api private
      #
      # @example Evaluate the name.
      #   Model.__evaluate__(:name)
      #
      # @param [ String, Symbol, Proc ] name The name.
      #
      # @return [ Symbol ] The value as a symbol.
      #
      # @since 3.1.0
      def __evaluate__(name)
        name.respond_to?(:call) ? name.call.to_sym : name.to_sym
      end

      # Get the name of the current database to use. Will check for a session
      # override with a database first, then database name.
      #
      # @api private
      #
      # @example Get the current database name.
      #   Model.current_database_name
      #
      # @param [ Moped::Session ] session The current session.
      #
      # @return [ Symbol ] The current database name.
      #
      # @since 3.1.0
      def current_database_name(session)
        if session_override && name = session.options[:database]
          name
        else
          database_name
        end
      end
    end
  end
end
