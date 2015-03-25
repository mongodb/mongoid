# encoding: utf-8
module Mongoid
  module Errors

    # Raised when options provided to :store_in are invalid.
    class InvalidStorageOptions < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidStorageOptions.new(Person, invalid_option: 'name')
      #
      # @param [ Class ] klass The model class.
      # @param [ Hash, String, Symbol ] options The provided options.
      #
      # @since 3.0.0
      def initialize(klass, options)
        super(
          compose_message(
            "invalid_storage_options",
            { klass: klass, options: options }
          )
        )
      end
    end
  end
end
