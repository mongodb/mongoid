# encoding: utf-8
module Mongoid #:nodoc:
  module Config #:nodoc:
    class ReplsetDatabase < Hash

      # Configure the database connections. This will return an array
      # containing one Mongo::DB and nil (to keep compatibility with Mongoid::Config::Database)
      # If you want the reads to go to a secondary node use the :read_secondary(true): option
      #
      # @example Configure the connection.
      #   db.configure
      #
      # @return [ Array<Mongo::DB, nil ] The Mongo databases.
      #
      # @since 2.0.0.rc.5
      def configure
        #yes, construction is weird but the driver wants "A list of host-port pairs ending with a hash containing any options"
        #mongo likes symbols
        options = self.inject({}) { |memo, (k, v)| memo[k.to_sym] = v; memo}
        connection = Mongo::ReplSetConnection.new(*(self['hosts'] << options))
        [ connection.db(self['database']), nil ]
      end

      # Create the new db configuration class.
      #
      # @example Initialize the class.
      #   Config::ReplsetDatabase.new(
      #     "hosts" => [[host1,port1],[host2,port2]]
      #   )
      #
      # replSet does not supports auth
      #
      # @param [ Hash ] options The configuration options.
      #
      # @option options [ Array ] :hosts The database host.
      # @option options [ String ] :database The database name.
      # @option options [ Boolean ] :read_secondary Tells the driver to read from secondaries.
      # ...
      #
      # @see Mongo::ReplSetConnection for all options
      #
      # @since 2.0.0.rc.5
      def initialize(options = {})
        merge!(options)
      end
    end
  end
end
