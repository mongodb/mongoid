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
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        ops = {}
        renames.each do |old_field, new_field|
          old_access = database_field_name(old_field)
          new_name = new_field.to_s
          attributes[new_name] = attributes.delete(old_access)
          remove_change(old_access)
          remove_change(new_name)
          ops[atomic_attribute_name(old_access)] = atomic_attribute_name(new_name)
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do |cs|
          cs.add(
            type: :update,
            collection: collection(_root),
            selector: selector,
            payload: positionally(selector, { '$rename' => ops }),
            document: self,
            session: _session
          )
        end
        self
      end
    end
  end
end
