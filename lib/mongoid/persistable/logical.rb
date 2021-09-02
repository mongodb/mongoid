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
        prepare_atomic_operation do |ops|
          process_atomic_operations(operations) do |field, values|
            value = attributes[field]
            values.each do |op, val|
              value = value & val if op.to_s == "and"
              value = value | val if op.to_s == "or"
            end
            process_attribute field, value if executing_atomically?
            attributes[field] = value
            ops[atomic_attribute_name(field)] = values
          end
          { "$bit" => ops } unless ops.empty?
        end
      end
    end
  end
end
