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
      #   document.max(field: 100)
      #
      # @param [ Hash<Symbol | String, Comparable> ] fields The fields to
      #   set, with corresponding minimum values.
      #
      # @return [ Document ] The document.
      def max(fields)
        prepare_atomic_operation do |ops|
          process_atomic_operations(fields) do |field, value|
            current_value = attributes[field]
            if value > current_value
              process_attribute field, value
              ops[atomic_attribute_name(field)] = value
            end
          end
          { "$max" => ops }
        end
      end
    end
  end
end
