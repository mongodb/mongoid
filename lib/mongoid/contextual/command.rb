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

      private

      # Execute the block setting field limitations.
      #
      # @api private
      #
      # @example Execute with field limitations.
      #   text_search.selecting do
      #     #...
      #   end
      #
      # @param [ Symbol ] param The name of the command parameter.
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 4.0.0
      def selecting(param)
        begin
          fields = command[param]
          Threaded.set_selection(criteria.object_id, fields) unless fields.blank?
          yield
        ensure
          Threaded.delete_selection(criteria.object_id)
        end
      end
    end
  end
end
