# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $inc operations.
    module Incrementable
      extend ActiveSupport::Concern

      # Increment the provided fields by the corresponding values. Values can
      # be positive or negative, and if no value exists for the field it will
      # be set with the provided value.
      #
      # @example Increment the fields.
      #   document.inc(score: 10, place: 1, lives: -10)
      #
      # @param [ Hash ] increments The field/inc increment pairs.
      #
      # @return [ Document ] The document.
      def inc(increments)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly

        dirty = _atomic_dirty_fields_init
        ops = {}

        increments.each do |field, value|
          access = database_field_name(field)
          increment = value.is_a?(BigDecimal) ? value.to_f : value
          current = attributes[access]
          _mark_dirty_field(dirty, access, current)
          attributes[access] = (current || 0) + increment
          _track_dirty_field(dirty, access)
          ops[atomic_attribute_name(access)] = increment
        end

        return self unless persisted?

        _stage_atomic_update('$inc', ops, dirty: dirty)
      end
    end
  end
end
