# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for setting a field (or fields) to the smaller of
    # either it's current value, or a given value.
    module Minable
      extend ActiveSupport::Concern

      # Set the given field or fields to the smaller of either it's current
      # value, or a given value.
      #
      # @example Set a field to be no more than 100.
      #   document.min(field: 100)
      #
      # @param [ Hash<Symbol | String, Comparable> ] fields The fields to
      #   set, with corresponding maximum values.
      #
      # @return [ Document ] The document.
      def set_min(fields)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        dirty = _atomic_dirty_fields_init
        ops = {}

        fields.each do |field, value|
          access = database_field_name(field)
          next unless value < attributes[access]

          process_attribute access, value
          _track_dirty_field(dirty, access)
          ops[atomic_attribute_name(access)] = value
        end

        _stage_atomic_update('$min', ops, dirty: dirty)
      end
      alias clamp_upper_bound set_min
    end
  end
end
