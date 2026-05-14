# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $pop operations.
    module Poppable
      extend ActiveSupport::Concern

      # Pop or shift items from arrays using the $pop operator.
      #
      # @example Pop items from an array.
      #   document.pop(aliases: 1)
      #
      # @example Shift items in the array.
      #   document.pop(aliases: -1)
      #
      # @example Multiple pops in one call.
      #   document.pop(names: 1, aliases: 1)
      #
      # @param [ Hash ] pops The field/value pop operations.
      #
      # @return [ Document ] The document.
      def pop(pops)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        ops = {}
        pops.each do |field, value|
          access = database_field_name(field)
          values = send(access)
          (value > 0) ? values.pop : values.shift
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
            payload: positionally(selector, { '$pop' => ops }),
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
