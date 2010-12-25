# encoding: utf-8

module Mongoid #:nodoc:
  module Config #:nodoc:

    # This class handles the configuration and initialization of the master
    # database.
    class Master < Hash

      # Configure the database connection. This will return the mongo db from
      # the connection.
      #
      # @example Configure the connection.
      #   master.configure
      #
      # @return [ Mongo::DB ] The Mongo database.
      def configure
        connection.db(name)
      end

      # Create the new master configuration class.
      #
      # @example Initialize the class.
      #   Config::Master.new("uri" => { "mongodb://localhost:27001/sushi" })
      #
      # @param [ Hash ] options The configuration options.
      #
      # @option options [ String ] :database The database name.
      # @option options [ String ] :host The database host.
      # @option options [ String ] :password The password for authentication.
      # @option options [ String ] :port The port for the database.
      # @option options [ String ] :uri The uri for the database.
      # @option options [ String ] :username The user for authentication.
      def initialize(options = {})
        merge!(options)
      end

      private

      # Do we need to authenticate against the database?
      #
      # @example Are we authenticating?
      #   master.authenticating?
      #
      # @return [ true, false ] True if auth is needed, false if not.
      def authenticating?
        username || password
      end

      # Takes the supplied options in the hash and created a URI from them to
      # pass to the Mongo connection object.
      #
      # @example Build the URI.
      #   master.build_uri
      #
      # @return [ String ] A mongo compliant URI string.
      def build_uri
        "mongodb://".tap do |base|
          base << "#{username}:#{password}@" if authenticating?
          base << "#{host || "localhost"}:#{port || 27017}"
          base << "/#{self["database"]}" if authenticating?
        end
      end

      # Create the mongo connection from either the supplied URI or a generated
      # one, while setting pool size and logging.
      #
      # @example Create the connection.
      #   master.connection
      #
      # @return [ Mongo::Connection ] The mongo connection.
      def connection
        Mongo::Connection.from_uri(
          uri, :pool_size => pool_size, :logger => Mongoid::Logger.new
        ).tap do |conn|
          conn.apply_saved_authentication
        end
      end

      # Convenience for accessing the hash via dot notation.
      #
      # @example Access a value in alternate syntax.
      #   master.host
      #
      # @return [ Object ] The value in the hash.
      def method_missing(name, *args, &block)
        self[name.to_s]
      end

      # Get the name of the database, from either the URI supplied or the
      # database value in the options.
      #
      # @example Get the database name.
      #   master.name
      #
      # @return [ String ] The database name.
      def name
        db_name = URI.parse(uri).path.to_s.sub("/", "")
        db_name.blank? ? database : db_name
      end

      # Get a Mongo compliant URI for the database connection.
      #
      # @example Get the URI.
      #   master.uri
      #
      # @return [ String ] The URI for the connection.
      def uri
        self["uri"] || build_uri
      end
    end
  end
end
