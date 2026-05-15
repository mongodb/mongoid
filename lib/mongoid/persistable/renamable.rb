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

        dirty = _atomic_dirty_fields_init
        ops = {}

        renames.each do |old_field, new_field|
          old_access = database_field_name(old_field)
          new_name = new_field.to_s
          _mark_dirty_field(dirty, old_access, attributes[old_access])
          _mark_dirty_field(dirty, new_name, nil)
          attributes[new_name] = attributes.delete(old_access)
          _track_dirty_field(dirty, old_access)
          _track_dirty_field(dirty, new_name)
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
            session: _session,
            skip_callbacks: true,
            dirty_fields: dirty
          )
        end
        self
      end
    end
  end
end
