# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to define a field type mapping with
    # invalid argument types.
    class InvalidFieldTypeDefinition < MongoidError

      # Create the new error.
      #
      # @example Instantiate the error.
      #   InvalidFieldTypeDefinition.new('number', 123)
      #
      # @param [ Object ] field_type The object which is expected to a be Symbol or String.
      # @param [ Object ] klass The object which is expected to be a Class or Module.
      def initialize(field_type, klass)
        type_inspection = field_type.try(:inspect) || field_type.class.inspect
        klass_inspection = klass.try(:inspect) || klass.class.inspect
        super(
          compose_message('invalid_field_type_definition',
            type_inspection: type_inspection, klass_inspection: klass_inspection)
        )
      end
    end
  end
end
