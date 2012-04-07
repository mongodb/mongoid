# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when options provided to :store_in are invalid.
    class InvalidStorageOptions < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidStorageOptions.new(:collection_name)
      #
      # @param [ Hash, String, Symbol ] options The provided options.
      #
      # @since 3.0.0
      def initialize(options)
        super(
          compose_message("invalid_storage_options", { options: options })
        )
      end
    end
  end
end
