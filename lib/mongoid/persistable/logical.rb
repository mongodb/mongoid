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
        # @example Execute a bitwise and on the field.
        #   person.bit(:age, { :and => 12 })
        #
        # @example Execute a bitwise or on the field.
        #   person.bit(:age, { :or => 12 })
        #
        # @example Execute a chain of bitwise operations.
        #   person.bit(:age, { :and => 10, :or => 12 })
        #
        # @param [ Symbol ] field The name of the field.
        # @param [ Hash ] value The bitwise operations to perform.
        # @param [ Hash ] options The mongo persistence options.
        #
        # @return [ Integer ] The new value of the field.
        #
        # @since 2.1.0
        # def bit(field, value, options = {})
          # Bit.new(self, field, value, options).persist
        # end

      def bit(operations)
        prepare_atomic_operation do |coll, selector, ops|
          operations.each do |field, values|
            normalized = database_field_name(field)
            value = send(field)
            values.each do |op, val|
              value = value & val if op.to_s == "and"
              value = value | val if op.to_s == "or"
            end
            attributes[normalized] = value
            remove_change(normalized)
            ops[atomic_attribute_name(normalized)] = values
          end
          coll.find(selector).update(positionally(selector, "$bit" => ops))
        end
      end
    end
  end
end
