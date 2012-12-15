# encoding: utf-8
module Mongoid
  module Errors

    # Raised when querying the database for a document by a specific id or by
    # set of attributes which does not exist. If multiple ids were passed then
    # it will display all of those.
    class DocumentNotFound < MongoidError

      attr_reader :klass, :params

      # Create the new error.
      #
      # @example Create the error.
      #   DocumentNotFound.new(Person, ["1", "2"])
      #
      # @example Create the error with attributes instead of ids
      #   DocumentNotFound.new(Person, :ssn => "1234", :name => "Helen")
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash, Array, Object ] params The attributes or ids.
      # @param [ Array ] unmatched The unmatched ids, if appropriate
      def initialize(klass, params, unmatched = nil)
        if !unmatched && !params.is_a?(Hash)
          raise ArgumentError, 'please also supply the unmatched ids'
        end
        @klass, @params = klass, params
        super(
          compose_message(
            message_key(params),
            {
              klass: klass.name,
              searched: searched(params),
              attributes: params,
              total: total(params),
              missing: missing(unmatched)
            }
          )
        )
      end

      private

      # Get the string to display the document params that were unmatched.
      #
      # @example Get the missing string.
      #   error.missing(1)
      #
      # @param [ Object, Array ] unmatched The ids that did not match.
      #
      # @return [ String ] The missing string.
      #
      # @since 3.0.0
      def missing(unmatched)
        if unmatched.is_a?(::Array)
          unmatched.join(", ")
        else
          unmatched
        end
      end

      # Get the string to display the document params that were searched for.
      #
      # @example Get the searched string.
      #   error.searched(1)
      #
      # @param [ Object, Array ] params The ids that were searched for.
      #
      # @return [ String ] The searched string.
      #
      # @since 3.0.0
      def searched(params)
        if params.is_a?(::Array)
          params.take(3).join(", ") + " ..."
        else
          params
        end
      end

      # Get the total number of expected documents.
      #
      # @example Get the total.
      #   error.total([ 1, 2, 3 ])
      #
      # @param [ Object, Array ] params What was searched for.
      #
      # @return [ Integer ] The total number.
      #
      # @since 3.0.0
      def total(params)
        params.is_a?(::Array) ? params.count : 1
      end

      # Create the problem.
      #
      # @example Create the problem.
      #   error.problem
      #
      # @return [ String ] The problem.
      #
      # @since 3.0.0
      def message_key(params)
        case params
          when Hash then "document_with_attributes_not_found"
          else "document_not_found"
        end
      end
    end
  end
end
