# frozen_string_literal: true

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
      # @param [ Hash | Array | Object ] params The attributes or ids.
      # @param [ Array | Hash ] unmatched The unmatched ids, if appropriate. If
      #   there is a shard key this will be a hash.
      def initialize(klass, params, unmatched = nil)
        if !unmatched && !params.is_a?(Hash)
          unmatched = Array(params) if params
        end

        @klass, @params = klass, params
        super(
          compose_message(
            message_key(params, unmatched),
            {
              klass: klass.name,
              searched: searched(params),
              attributes: params,
              total: total(params),
              missing: missing(unmatched),
              shard_key: shard_key(unmatched)
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
      # @param [ Object | Array ] unmatched The ids that did not match.
      #
      # @return [ String ] The missing string.
      def missing(unmatched)
        if unmatched.is_a?(::Array)
          unmatched.join(", ")
        elsif unmatched.is_a?(::Hash)
          unmatched[:_id] || unmatched["_id"]
        else
          unmatched
        end
      end

      # Get the string to display the document params that were searched for.
      #
      # @example Get the searched string.
      #   error.searched(1)
      #
      # @param [ Object | Array ] params The ids that were searched for.
      #
      # @return [ String ] The searched string.
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
      # @param [ Object | Array ] params What was searched for.
      #
      # @return [ Integer ] The total number.
      def total(params)
        params.is_a?(::Array) ? params.count : 1
      end

      # Create the problem.
      #
      # @example Create the problem.
      #   error.problem
      #
      # @return [ String ] The problem.
      def message_key(params, unmatched)
        if !params && !unmatched
          "no_documents_found"
        elsif Hash === params
          "document_with_attributes_not_found"
        elsif Hash === unmatched && unmatched.size >= 2
          "document_with_shard_key_not_found"
        else
          "document_not_found"
        end
      end

      # Get the shard key from the unmatched hash.
      #
      # @return [ String ] the shard key and value.
      def shard_key(unmatched)
        if Hash === unmatched
          h = unmatched.dup
          h.delete("_id")
          h.delete(:_id)
          h.map{|k,v| "#{k}: #{v}" }.join(", ")
        end
      end
    end
  end
end
