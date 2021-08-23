# frozen_string_literal: true

module Mongoid
  module Contextual
    module Command

      # @attribute [r] collection The collection to query against.
      # @attribute [r] criteria The criteria for the context.
      attr_reader :collection, :criteria

      # The database command that is being built to send to the db.
      #
      # @example Get the command.
      #   command.command
      #
      # @return [ Hash ] The db command.
      def command
        @command ||= {}
      end

      # Get the database client.
      #
      # @example Get the client.
      #   command.client
      #
      # @return [ Mongo::Client ] The Mongo client.
      def client
        collection.database.client
      end
    end
  end
end
