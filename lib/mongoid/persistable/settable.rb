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
        prepare_atomic_operation do |ops|
          process_atomic_operations(setters) do |field, value|

            field_seq = field.to_s.split('.')
            field = field_seq.shift
            if field_seq.length > 0
              # nested hash path
              old_value = attributes[field]

              # if the old value is not a hash, clobber it
              unless Hash === old_value
                old_value = {}
              end

              # descend into the hash, creating intermediate keys as needed
              cur_value = old_value
              while field_seq.length > 1
                cur_key = field_seq.shift
                # clobber on each level if type is not a hash
                unless Hash === cur_value[cur_key]
                  cur_value[cur_key] = {}
                end
                cur_value = cur_value[cur_key]
              end

              # now we are on the leaf level, perform the set
              # and overwrite whatever was on this level before
              cur_value[field_seq.shift] = value

              # and set value to the value of the top level field
              # because this is what we pass to $set
              value = old_value
            end

            process_attribute(field, value)

            unless relations.include?(field.to_s)
              ops[atomic_attribute_name(field)] = attributes[field]
            end
          end
          { "$set" => ops } unless ops.empty?
        end
      end
    end
  end
end
