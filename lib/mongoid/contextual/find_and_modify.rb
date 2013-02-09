# encoding: utf-8
module Mongoid
  module Contextual
    class FindAndModify
      include Command

      # @attribute [r] criteria The criteria for the context.
      # @attribute [r] options The command options.
      # @attribute [r] update The updates.
      # @attribute [r] query The Moped query.
      attr_reader :criteria, :options, :update, :query

      # Initialize the find and modify command, used for MongoDB's
      # $findAndModify.
      #
      # @example Initialize the command.
      #   FindAndModify.new(criteria, { "$set" => { likes: 1 }})
      #
      # @param [ Criteria ] criteria The criteria.
      # @param [ Hash ] update The updates.
      # @param [ Hash ] options The command options.
      #
      # @option options [ true, false ] :new Return the updated document.
      # @option options [ true, false ] :remove Delete the first document.
      # @option options [ true, false ] :upsert Create the document if it doesn't exist.
      #
      # @since 3.0.0
      def initialize(collection, criteria, update, options = {})
        @collection, @criteria, @options, @update =
          collection, criteria, options, update.mongoize
        @query = collection.find(criteria.selector)
        apply_criteria_options
      end

      # Get the result of the $findAndModify.
      #
      # @example Get the result.
      #   find_and_modify.result
      #
      # @return [ Hash ] The result of the command.
      #
      # @since 3.0.0
      def result
        query.modify(update, options)
      end

      private

      # Apply criteria specific options - query, sort, fields.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   find_and_modify.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      #
      # @since 3.0.0
      def apply_criteria_options
        if spec = criteria.options[:sort]
          query.sort(spec)
        end
        if spec = criteria.options[:fields]
          query.select(spec)
        end
      end
    end
  end
end
