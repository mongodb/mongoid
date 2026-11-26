# frozen_string_literal: true

module Mongoid
  module Validatable
    # A specialization of the ActiveModel numericality validator, which adds
    # logic to recognize and accept BSON::Decimal128 as a number.
    class NumericalityValidator < ActiveModel::Validations::NumericalityValidator
      # Reimplements EachValidator#validate in order to work around Mongoid's
      # nonstandard type-casting of String values.
      #
      # @param [ Document ] record The document to validate.
      def validate(record)
        attributes.each do |attribute|
          value = raw_value_for_validation(record, attribute)
          next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])

          value = prepare_value_for_validation(value, record, attribute)
          validate_each(record, attribute, value)
        end
      end

      private

      # Ensure that BSON::Decimal128 is treated as a BigDecimal during the
      # validation step.
      def prepare_value_for_validation(value, _record, _attr_name)
        value.is_a?(BSON::Decimal128) ? value.to_big_decimal : value
      end

      # Fetches the raw value from the record, prior to any typecasting being
      # applied. Attributes that are not fields are read as ActiveModel does.
      def raw_value_for_validation(record, attr)
        attribute = record.database_field_name(attr)
        return nil if record.relations.key?(attribute)
        return record.read_attribute_for_validation(attr) if !record.fields.key?(attribute) && record.respond_to?(attr, true)

        record.read_attribute_before_type_cast(attribute)
      end
    end
  end
end
