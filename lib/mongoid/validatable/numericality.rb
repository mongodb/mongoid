# frozen_string_literal: true

module Mongoid
  module Validatable
    # A specialization of the ActiveModel numericality validator, which adds
    # logic to recognize and accept BSON::Decimal128 as a number.
    class NumericalityValidator < ActiveModel::Validations::NumericalityValidator
      # Reimplements EachValidator#validate in order to work around Mongoid's
      # nonstandard type-casting of String values.
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
      def prepare_value_for_validation(value, record, attr_name)
        result = super

        result.is_a?(BSON::Decimal128) ? result.to_big_decimal : result
      end

      def raw_value_for_validation(record, attr)
        attribute = record.database_field_name(attr)
        return nil if record.relations.key?(attribute)

        record.read_attribute_before_type_cast(attribute)
      end
    end
  end
end
