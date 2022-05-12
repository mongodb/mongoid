# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to define a field using a :type option value
    # that is not present in the field type mapping.
    class InvalidFieldType < MongoidError

      # Create the new error.
      #
      # @example Instantiate the error.
      #   InvalidFieldType.new('Person', 'first_name', 'stringgy')
      #
      # @param [ String ] klass The model class.
      # @param [ String ] field The field on which the invalid type is used.
      # @param [ Symbol | String ] type The value of the field :type option.
      def initialize(klass, field, type)
        super(
          compose_message('invalid_field_type',
            klass: klass, field: field, type_inspection: type.inspect)
        )
      end
    end
  end
end
