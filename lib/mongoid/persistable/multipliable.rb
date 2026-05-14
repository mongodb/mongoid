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

        ops = {}
        factors.each do |field, value|
          access = database_field_name(field)
          factor = value.is_a?(BigDecimal) ? value.to_f : value
          current = attributes[access]
          attributes[access] = (current || 0) * factor
          remove_change(access)
          ops[atomic_attribute_name(access)] = factor
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do |cs|
          cs.add(
            type: :update,
            collection: collection(_root),
            selector: selector,
            payload: positionally(selector, { '$mul' => ops }),
            document: self,
            session: _session,
            skip_callbacks: true
          )
        end
        self
      end
    end
  end
end
