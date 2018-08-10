# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for $set operations.
    #
    # @since 4.0.0
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
      # @param [ Hash ] setters The field/value pairs to set.
      #
      # @return [ Document ] The document.
      #
      # @since 4.0.0
      def set(setters)
        prepare_atomic_operation do |ops|
          process_atomic_operations(setters) do |field, value|

            field_and_value_hash = hasherizer(field.split('.'), value)
            field = field_and_value_hash.keys.first.to_s
            value = field_and_value_hash[field]

            if fields[field] && fields[field].type == Hash && attributes.key?(field) && Hash === value && !value.empty?
              merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
              value = (attributes[field] || {}).merge(value, &merger)
            end

            process_attribute(field.to_s, value)

            unless relations.include?(field.to_s)
              ops[atomic_attribute_name(field)] = attributes[field]
            end
          end
          { "$set" => ops } unless ops.empty?
        end
      end
    end

    def hasherizer(keys, value)
      return value if keys.empty?
      {}.tap { |hash| hash[keys.shift] = hasherizer(keys, value) }
    end
  end
end
