# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $unset operations.
    #
    # @since 4.0.0
    module Unsettable
      extend ActiveSupport::Concern

      # Perform an $unset operation on the provided fields and in the
      # values in the document in memory.
      #
      # @example Unset the values.
      #   document.unset(:first_name, :last_name, :middle)
      #
      # @param [ Array<String, Symbol> ] fields The names of the fields to
      #   unset.
      #
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def unset(*fields)
        prepare_atomic_operation do |ops|
          fields.flatten.each do |field|
            normalized = database_field_name(field)
            attributes.delete(normalized)
            ops[atomic_attribute_name(normalized)] = true
          end
          { "$unset" => ops }
        end
      end
    end
  end
end

