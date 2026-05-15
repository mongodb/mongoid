# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for logical bitwise operations.
    module Logical
      extend ActiveSupport::Concern

      # Performs an atomic $bit operation on the field with the provided hash
      # of bitwise ops to execute in order.
      #
      # @example Execute the bitwise operations.
      #   person.bit(age: { :and => 12 }, val: { and: 10, or: 12 })
      #
      # @param [ Hash ] operations The bitwise operations.
      #
      # @return [ Document ] The document.
      def bit(operations)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        dirty = _atomic_dirty_fields_init
        ops = {}

        operations.each do |field, values|
          access = database_field_name(field)
          current = attributes[access]
          _mark_dirty_field(dirty, access, current)
          value = current
          values.each do |op, val|
            value &= val if op.to_s == 'and'
            value |= val if op.to_s == 'or'
          end
          attributes[access] = value
          _track_dirty_field(dirty, access)
          ops[atomic_attribute_name(access)] = values
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do |cs|
          cs.add(
            type: :update,
            collection: collection(_root),
            selector: selector,
            payload: positionally(selector, { '$bit' => ops }),
            document: self,
            session: _session,
            skip_callbacks: true,
            dirty_fields: dirty
          )
        end
        self
      end
    end
  end
end
