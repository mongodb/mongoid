# encoding: utf-8
module Mongoid
  module Contextual
    module Command

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

      # Get the criteria for the command.
      #
      # @example Get the criteria.
      #   command.criteria
      #
      # @return [ Criteria ] The criteria.
      #
      # @since 3.0.0
      def criteria
        @criteria
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
        criteria.klass.mongo_session
      end
    end
  end
end
