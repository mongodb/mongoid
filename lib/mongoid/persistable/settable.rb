# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for $set operations.
    module Settable
      extend ActiveSupport::Concern

      # Perform a $set operation on the provided field/value pairs and set the
      # values in the document in memory.
      #
      # @example Set the values.
      #   document.set(title: "sir", dob: Date.new(1970, 1, 1))
      #
      # The key can be a dotted sequence of keys, in which case the
      # top level field is treated as a nested hash and any missing keys
      # are created automatically:
      #
      # @example Set the values using nested hash semantics.
      #   document.set('author.title' => 'Sir')
      #   # => document.author == {'title' => 'Sir'}
      #
      # Performing a nested set like this merges values of intermediate keys:
      #
      # @example Nested hash value merging.
      #   document.set('author.title' => 'Sir')
      #   document.set('author.name' => 'Linus Torvalds')
      #   # => document.author == {'title' => 'Sir', 'name' => 'Linus Torvalds'}
      #
      # If the top level field was not a hash, its original value is discarded
      # and the field is replaced with a hash.
      #
      # @example Nested hash overwriting a non-hash value.
      #   document.set('author' => 'John Doe')
      #   document.set('author.title' => 'Sir')
      #   # => document.author == {'title' => 'Sir'}
      #
      # Note that unlike MongoDB's $set, Mongoid's set writes out the entire
      # field even when setting a subset of the field via the nested hash
      # semantics. This means performing a $set with nested hash semantics
      # can overwrite other hash keys within the top level field in the database.
      #
      # @param [ Hash ] setters The field/value pairs to set.
      #
      # @return [ Document ] The document.
      def set(setters)
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self unless persisted?

        dirty = _atomic_dirty_fields_init
        ops = {}

        setters.each do |field, value|
          access = database_field_name(field)
          field_seq = access.to_s.split('.')
          top_field = field_seq.shift
          value = _set_nested(top_field, field_seq, value) if field_seq.length > 0
          process_attribute(top_field, value)
          _track_dirty_field(dirty, top_field)
          ops[atomic_attribute_name(top_field)] = attributes[top_field] unless relations.include?(top_field)
        end

        return self if ops.empty?

        selector = atomic_selector
        Mongoid.changeset do |cs|
          cs.add(
            type: :update,
            collection: collection(_root),
            selector: selector,
            payload: positionally(selector, { '$set' => ops }),
            document: self,
            session: _session,
            skip_callbacks: true,
            dirty_fields: dirty
          )
        end
        self
      end

      private

      # Build the nested-hash value for a dotted field path.
      #
      # Descends into the top-level field's current hash value (creating
      # intermediate keys as needed), sets the leaf, and returns the updated
      # top-level hash to be written back via process_attribute.
      #
      # @api private
      #
      # @param [ String ] top_field The top-level attribute name.
      # @param [ Array<String> ] field_seq Remaining path segments (without top).
      # @param [ Object ] value The leaf value to assign.
      #
      # @return [ Hash ] The updated top-level hash value.
      def _set_nested(top_field, field_seq, value)
        old_value = attributes[top_field]
        old_value = {} unless old_value.is_a?(Hash)
        cur_value = old_value
        while field_seq.length > 1
          cur_key = field_seq.shift
          cur_value[cur_key] = {} unless cur_value[cur_key].is_a?(Hash)
          cur_value = cur_value[cur_key]
        end
        cur_value[field_seq.shift] = value
        old_value
      end
    end
  end
end
