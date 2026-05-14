# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for setting a field (or fields) to the larger of
    # either it's current value, or a given value.
    module Maxable
      extend ActiveSupport::Concern

      # Set the given field or fields to the larger of either it's current
      # value, or a given value.
      #
      # @example Set a field to be no less than 100.
      #   document.set_max(field: 100)
      #
      # @param [ Hash<Symbol | String, Comparable> ] fields The fields to
      #   set, with corresponding minimum values.
      #
      # @return [ Document ] The document.
      def set_max(fields)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        ops = {}
        fields.each do |field, value|
          access = database_field_name(field)
          current_value = attributes[access]
          next unless value > current_value

          process_attribute access, value
          remove_change(access)
          ops[atomic_attribute_name(access)] = value
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do |cs|
          cs.add(
            type: :update,
            collection: collection(_root),
            selector: selector,
            payload: positionally(selector, { '$max' => ops }),
            document: self,
            session: _session
          )
        end
        self
      end
      alias clamp_lower_bound set_max
    end
  end
end
