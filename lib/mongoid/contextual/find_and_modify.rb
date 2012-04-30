# encoding: utf-8
module Mongoid
  module Contextual
    class FindAndModify
      include Command

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
      #
      # @since 3.0.0
      def initialize(criteria, update, options = {})
        @criteria = criteria
        command[:findandmodify] = criteria.klass.collection_name.to_s
        command[:update] = update unless options[:remove]
        command.merge!(options)
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
        session.with(consistency: :strong) do |session|
          session.command(command)["value"]
        end
      end

      private

      # Apply criteria specific options - query, sort, fields.
      #
      # @api private
      #
      # @example Apply the criteria options
      #   map_reduce.apply_criteria_options
      #
      # @return [ nil ] Nothing.
      #
      # @since 3.0.0
      def apply_criteria_options
        command[:query] = criteria.selector
        if sort = criteria.options[:sort]
          command[:sort] = sort
        end
        if fields = criteria.options[:fields]
          command[:fields] = fields
        end
      end
    end
  end
end
