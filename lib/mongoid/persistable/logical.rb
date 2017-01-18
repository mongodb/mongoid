# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for logical bitwise operations.
    #
    # @since 4.0.0
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
      #
      # @since 4.0.0
      def bit(operations)
        prepare_atomic_operation do |ops|
          process_atomic_operations(operations) do |field, values|
            value = attributes[field]
            values.each do |op, val|
              value = value & val if op.to_s == "and"
              value = value | val if op.to_s == "or"
            end
            attributes[field] = value
            ops[atomic_attribute_name(field)] = values
          end
          { "$bit" => ops }
        end
      end
    end
  end
end
