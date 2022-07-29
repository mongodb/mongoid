# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for $unset operations.
    module Unsettable
      extend ActiveSupport::Concern

      # Perform an $unset operation on the provided fields and in the
      # values in the document in memory.
      #
      # @example Unset the values.
      #   document.unset(:first_name, :last_name, :middle)
      #
      # @param [ [ String | Symbol | Array<String | Symbol>]... ] *fields
      #   The names of the field(s) to unset.
      #
      # @return [ Document ] The document.
      def unset(*fields)
        prepare_atomic_operation do |ops|
          fields.flatten.each do |field|
            normalized = database_field_name(field)
            if executing_atomically?
              process_attribute normalized, nil
            else
              attributes.delete(normalized)
            end
            ops[atomic_attribute_name(normalized)] = true
          end
          { "$unset" => ops }
        end
      end
    end
  end
end
