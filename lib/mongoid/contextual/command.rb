# encoding: utf-8
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
      #
      # @since 3.0.0
      def command
        @command ||= {}
      end

      # Get the database session.
      #
      # @example Get the session.
      #   command.session
      #
      # @return [ Session ] The Moped session.
      #
      # @since 3.0.0
      def session
        collection.database.session
      end
    end
  end
end
