# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $unset operations.
    module Unsettable
      extend ActiveSupport::Concern

      # Perform an $unset operation on the provided fields and in the
      # values in the document in memory.
      #
      # @example Unset the values.
      #   document.unset(:first_name, :last_name, :middle)
      #
      # @param [ [ String | Symbol | Array<String | Symbol>]... ] *fields
      #   The names of the field(s) to unset.
      #
      # @return [ Document ] The document.
      def unset(*fields)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        dirty = _atomic_dirty_fields_init
        ops = {}

        fields.flatten.each do |field|
          normalized = database_field_name(field)
          process_attribute normalized, nil
          _track_dirty_field(dirty, normalized)
          ops[atomic_attribute_name(normalized)] = true
        end

        _stage_atomic_update('$unset', ops, dirty: dirty)
      end
    end
  end
end
