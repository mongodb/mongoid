# encoding: utf-8
require "mongoid/sessions/factory"
require "mongoid/sessions/validators"
require "mongoid/sessions/storage_options"
require "mongoid/sessions/thread_options"
require "mongoid/sessions/options"

module Mongoid
  module Sessions
    extend ActiveSupport::Concern
    include StorageOptions
    include ThreadOptions
    include Options

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
      super || self.class.mongo_session
    end

    def collection_name
      super || self.class.collection_name
    end

    module ClassMethods

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
        session = Sessions.with_name(session_name)
        session.use(database_name)
        self.persistence_options ? session.with(self.persistence_options) : session
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
    end
  end
end
