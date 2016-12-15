# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when attempting to demongoize a value from the database
    # that doesn't map to the field type.
    class UnmappedBSONType < MongoidError

      # Create the unmapped BSON type error.
      #
      # @example Create the new unmapped BSON type error.
      #   EagerLoad.new(:preferences)
      #
      # @param [ Symbol ] value The object that cannot be mapped.
      #
      # @since 6.1.0
      def initialize(value)
        super(compose_message("unmapped_bson_type", { value: value }))
      end
    end
  end
end
