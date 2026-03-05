# frozen_string_literal: true
# rubocop:todo all

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
        prepare_atomic_operation do |ops|
          process_atomic_operations(fields) do |field, value|
            current_value = attributes[field]
            if value > current_value
              process_attribute field, value
              ops[atomic_attribute_name(field)] = value
            end
          end
          { "$max" => ops } unless ops.empty?
        end
      end
      alias :clamp_lower_bound :set_max
    end
  end
end
