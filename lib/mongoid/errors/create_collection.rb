# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when an attempt to create a collection failed.
    class CreateCollection < MongoidError

      # Instantiate the create collection error.
      #
      # @param [ String ] collection_name The name of the collection that
      #   Mongoid failed to create.
      # @param [ Hash ] collection_options The options that were used when
      #   tried to create the collection.
      # @param [ String ] server_error The error raised by the server when
      #   tried to create the collection.
      def initialize(collection_name, collection_options, server_error)
        super(
            compose_message(
                "create_collection",
                {
                  collection_name: collection_name,
                  collection_options: collection_options,
                  server_error: server_error
                }
            )
        )
      end
    end
  end
end
