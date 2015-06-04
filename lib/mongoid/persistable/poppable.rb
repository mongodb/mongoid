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
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def pop(pops)
        prepare_atomic_operation do |ops|
          process_atomic_operations(pops) do |field, value|
            values = send(field)
            value > 0 ? values.pop : values.shift
            ops[atomic_attribute_name(field)] = value
          end
          { "$pop" => ops }
        end
      end
    end
  end
end
