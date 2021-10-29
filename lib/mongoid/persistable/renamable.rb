# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for $rename operations.
    module Renamable
      extend ActiveSupport::Concern

      # Rename fields from one value to another via $rename.
      #
      # @example Rename the fields.
      #   document.rename(title: "salutation", name: "nombre")
      #
      # @note This does not work for fields in embeds many associations.
      #
      # @param [ Hash ] renames The rename pairs of old name/new name.
      #
      # @return [ Document ] The document.
      def rename(renames)
        prepare_atomic_operation do |ops|
          process_atomic_operations(renames) do |old_field, new_field|
            new_name = new_field.to_s
            if executing_atomically?
              process_attribute new_name, attributes[old_field]
              process_attribute old_field, nil
            else
              attributes[new_name] = attributes.delete(old_field)
            end
            ops[atomic_attribute_name(old_field)] = atomic_attribute_name(new_name)
          end
          { "$rename" => ops }
        end
      end
    end
  end
end
