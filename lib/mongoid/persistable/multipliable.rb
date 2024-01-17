# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Persistable

    # Defines behavior for $mul operations.
    module Multipliable
      extend ActiveSupport::Concern

      # Multiply the provided fields by the corresponding values. Values can
      # be positive or negative, and if no value exists for the field it will
      # be set to zero.
      #
      # @example Multiply the fields.
      #   document.mul(score: 10, place: 1, lives: -10)
      #
      # @param [ Hash ] factors The field/factor multiplier pairs.
      #
      # @return [ Document ] The document.
      def mul(factors)
        prepare_atomic_operation do |ops|
          process_atomic_operations(factors) do |field, value|
            factor = value.is_a?(BigDecimal) ? value.to_f : value
            current = attributes[field]
            new_value = (current || 0) * factor
            process_attribute field, new_value if executing_atomically?
            attributes[field] = new_value
            ops[atomic_attribute_name(field)] = factor
          end
          { "$mul" => ops } unless ops.empty?
        end
      end
    end
  end
end
