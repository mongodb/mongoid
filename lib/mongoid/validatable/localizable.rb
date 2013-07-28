# encoding: utf-8
module Mongoid
  module Validatable

    # Adds localization support to validations.
    module Localizable

      # Validates each for localized fields.
      #
      # @example Validate localized fields.
      #   validator.validate_each(model, :name, "value")
      #
      # @param [ Document ] document The document.
      # @param [ Symbol, String ] attribute The attribute to validate.
      # @param [ Object ] value The attribute value.
      #
      # @since 2.4.2
      def validate_each(document, attribute, value)
        field = document.fields[document.database_field_name(attribute)]
        if field.try(:localized?) && !value.blank?
          value.values.each do |_value|
            super(document, attribute, _value)
          end
        else
          super
        end
      end
    end
  end
end
