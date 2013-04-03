# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $pop operations.
    #
    # @since 4.0.0
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
      # @return [ true, false ] If the operation succeeded.
      #
      # @since 4.0.0
      def pop(pops)
        prepare_atomic_operation do |coll, selector, ops|
          pops.each do |field, value|
            normalized = database_field_name(field)
            values = send(field)
            value > 0 ? values.pop : values.shift
            remove_change(normalized)
            ops[atomic_attribute_name(normalized)] = value
          end
          coll.find(selector).update(positionally(selector, "$pop" => ops))
        end
      end
    end
  end
end
