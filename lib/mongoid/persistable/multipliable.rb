# frozen_string_literal: true

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
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        dirty = _atomic_dirty_fields_init
        ops = {}

        factors.each do |field, value|
          access = database_field_name(field)
          factor = value.is_a?(BigDecimal) ? value.to_f : value
          current = attributes[access]
          _mark_dirty_field(dirty, access, current)
          attributes[access] = (current || 0) * factor
          _track_dirty_field(dirty, access)
          ops[atomic_attribute_name(access)] = factor
        end

        _stage_atomic_update('$mul', ops, dirty: dirty)
      end
    end
  end
end
