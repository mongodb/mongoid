# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when an attempt to drop a collection failed.
    class DropCollectionFailure < MongoidError

      # Instantiate the drop collection error.
      #
      # @param [ String ] collection_name The name of the collection that
      #   Mongoid failed to drop.
      #
      # @api private
      def initialize(collection_name, collection_options, error)
        super(
            compose_message(
                "drop_collection_failure",
                {
                  collection_name: collection_name
                }
            )
        )
      end
    end
  end
end
