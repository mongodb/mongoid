# encoding: utf-8
module Mongoid
  module Sessions
    class MongoUri

      SCHEME = /(mongodb:\/\/)/
      USER = /([-.\w:]+)/
      PASS = /([^@,]+)/
      NODES = /((([-.\w]+)(?::(\w+))?,?)+)/
      DATABASE = /(?:\/([-\w]+))?/

      URI = /#{SCHEME}(#{USER}:#{PASS}@)?#{NODES}#{DATABASE}/

      attr_reader :match

      # Get the database provided in the URI.
      #
      # @example Get the database.
      #   uri.database
      #
      # @return [ String ] The database.
      #
      # @since 3.0.0
      def database
        @database ||= match[9]
      end

      # Get the hosts provided in the URI.
      #
      # @example Get the hosts.
      #   uri.hosts
      #
      # @return [ Array<String> ] The hosts.
      #
      # @since 3.0.0
      def hosts
        @hosts ||= match[5].split(",")
      end

      # Create the new uri from the provided string.
      #
      # @example Create the new uri.
      #   MongoUri.new(uri)
      #
      # @param [ String ] string The uri string.
      #
      # @since 3.0.0
      def initialize(string)
        @match = string.match(URI)
      end

      # Get the password provided in the URI.
      #
      # @example Get the password.
      #   uri.password
      #
      # @return [ String ] The password.
      #
      # @since 3.0.0
      def password
        @password ||= match[4]
      end

      # Get the uri as a Mongoid friendly configuration hash.
      #
      # @example Get the uri as a hash.
      #   uri.to_hash
      #
      # @return [ Hash ] The uri as options.
      #
      # @since 3.0.0
      def to_hash
        config = { database: database, hosts: hosts }
        if username && password
          config.merge!(username: username, password: password)
        end
        config
      end

      # Get the username provided in the URI.
      #
      # @example Get the username.
      #   uri.username
      #
      # @return [ String ] The username.
      #
      # @since 3.0.0
      def username
        @username ||= match[3]
      end
    end
  end
end
