# frozen_string_literal: true

module Mongoid
  module Atomic

    # This class contains the logic for supporting atomic operations against the
    # database.
    class Modifiers < Hash

      # Add the atomic $addToSet modifiers to the hash.
      #
      # @example Add the $addToSet modifiers.
      #   modifiers.add_to_set({ "preference_ids" => [ "one" ] })
      #
      # @param [ Hash ] modifications The add to set modifiers.
      def add_to_set(modifications)
        modifications.each_pair do |field, value|
          if add_to_sets.has_key?(field)
            value.each do |val|
              add_to_sets[field]["$each"].push(val)
            end
          else
            add_to_sets[field] = { "$each" => value }
          end
        end
      end

      # Adds pull all modifiers to the modifiers hash.
      #
      # @example Add pull all operations.
      #   modifiers.pull_all({ "addresses" => { "street" => "Bond" }})
      #
      # @param [ Hash ] modifications The pull all modifiers.
      def pull_all(modifications)
        modifications.each_pair do |field, value|
          add_operation(pull_alls, field, value)
          pull_fields[field.split(".", 2)[0]] = field
        end
      end

      # Adds pull all modifiers to the modifiers hash.
      #
      # @example Add pull all operations.
      #   modifiers.pull({ "addresses" => { "_id" => { "$in" => [ 1, 2, 3 ]}}})
      #
      # @param [ Hash ] modifications The pull all modifiers.
      def pull(modifications)
        modifications.each_pair do |field, value|
          pulls[field] = value
          pull_fields[field.split(".", 2)[0]] = field
        end
      end

      # Adds push modifiers to the modifiers hash.
      #
      # @example Add push operations.
      #   modifiers.push({ "addresses" => { "street" => "Bond" }})
      #
      # @param [ Hash ] modifications The push modifiers.
      def push(modifications)
        modifications.each_pair do |field, value|
          push_fields[field] = field
          mods = push_conflict?(field) ? conflicting_pushes : pushes
          add_operation(mods, field, { '$each' => Array.wrap(value) })
        end
      end

      # Adds set operations to the modifiers hash.
      #
      # @example Add set operations.
      #   modifiers.set({ "title" => "sir" })
      #
      # @param [ Hash ] modifications The set modifiers.
      def set(modifications)
        modifications.each_pair do |field, value|
          next if field == "_id"
          mods = set_conflict?(field) ? conflicting_sets : sets
          add_operation(mods, field, value)
          set_fields[field.split(".", 2)[0]] = field
        end
      end

      # Adds unset operations to the modifiers hash.
      #
      # @example Add unset operations.
      #   modifiers.unset([ "addresses" ])
      #
      # @param [ Array<String> ] modifications The unset association names.
      def unset(modifications)
        modifications.each do |field|
          unsets.update(field => true)
        end
      end

      private

      # Add the operation to the modifications, either appending or creating a
      # new one.
      #
      # @example Add the operation.
      #   modifications.add_operation(mods, field, value)
      #
      # @param [ Hash ] mods The modifications.
      # @param [ String ] field The field.
      # @param [ Hash ] value The atomic op.
      def add_operation(mods, field, value)
        if mods.has_key?(field)
          if mods[field].is_a?(Array)
            value.each do |val|
              mods[field].push(val)
            end
          elsif mods[field]['$each']
            mods[field]['$each'].concat(value['$each'])
          end
        else
          mods[field] = value
        end
      end

      # Adds or appends an array operation with the $each specifier used
      # in conjuction with $push.
      #
      # @example Add the operation.
      #   modifications.add_operation(mods, field, value)
      #
      # @param [ Hash ] mods The modifications.
      # @param [ String ] field The field.
      # @param [ Hash ] value The atomic op.
      def add_each_operation(mods, field, value)
        if mods.has_key?(field)
          value.each do |val|
            mods[field]["$each"].push(val)
          end
        else
          mods[field] = { "$each" => value }
        end
      end

      # Get the $addToSet operations or initialize a new one.
      #
      # @example Get the $addToSet operations.
      #   modifiers.add_to_sets
      #
      # @return [ Hash ] The $addToSet operations.
      def add_to_sets
        self["$addToSet"] ||= {}
      end

      # Is the operation going to be a conflict for a $set?
      #
      # @example Is this a conflict for a set?
      #   modifiers.set_conflict?(field)
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def set_conflict?(field)
        name = field.split(".", 2)[0]
        pull_fields.has_key?(name) || push_fields.has_key?(name)
      end

      # Is the operation going to be a conflict for a $push?
      #
      # @example Is this a conflict for a push?
      #   modifiers.push_conflict?(field)
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def push_conflict?(field)
        name = field.split(".", 2)[0]
        set_fields.has_key?(name) || pull_fields.has_key?(name) ||
          (push_fields.keys.count { |item| item.split('.', 2).first == name } > 1)
      end

      # Get the conflicting pull modifications.
      #
      # @example Get the conflicting pulls.
      #   modifiers.conflicting_pulls
      #
      # @return [ Hash ] The conflicting pull operations.
      def conflicting_pulls
        conflicts["$pullAll"] ||= {}
      end

      # Get the conflicting push modifications.
      #
      # @example Get the conflicting pushs.
      #   modifiers.conflicting_pushs
      #
      # @return [ Hash ] The conflicting push operations.
      def conflicting_pushes
        conflicts["$push"] ||= {}
      end

      # Get the conflicting set modifications.
      #
      # @example Get the conflicting sets.
      #   modifiers.conflicting_sets
      #
      # @return [ Hash ] The conflicting set operations.
      def conflicting_sets
        conflicts["$set"] ||= {}
      end

      # Get the push operations that would have conflicted with the sets.
      #
      # @example Get the conflicts.
      #   modifiers.conflicts
      #
      # @return [ Hash ] The conflicting modifications.
      def conflicts
        self[:conflicts] ||= {}
      end

      # Get the names of the fields that need to be pulled.
      #
      # @example Get the pull fields.
      #   modifiers.pull_fields
      #
      # @return [ Array<String> ] The pull fields.
      def pull_fields
        @pull_fields ||= {}
      end

      # Get the names of the fields that need to be pushed.
      #
      # @example Get the push fields.
      #   modifiers.push_fields
      #
      # @return [ Array<String> ] The push fields.
      def push_fields
        @push_fields ||= {}
      end

      # Get the names of the fields that need to be set.
      #
      # @example Get the set fields.
      #   modifiers.set_fields
      #
      # @return [ Array<String> ] The set fields.
      def set_fields
        @set_fields ||= {}
      end

      # Get the $pullAll operations or initialize a new one.
      #
      # @example Get the $pullAll operations.
      #   modifiers.pull_alls
      #
      # @return [ Hash ] The $pullAll operations.
      def pull_alls
        self["$pullAll"] ||= {}
      end

      # Get the $pull operations or initialize a new one.
      #
      # @example Get the $pull operations.
      #   modifiers.pulls
      #
      # @return [ Hash ] The $pull operations.
      def pulls
        self["$pull"] ||= {}
      end

      # Get the $push/$each operations or initialize a new one.
      #
      # @example Get the $push/$each operations.
      #   modifiers.pushes
      #
      # @return [ Hash ] The $push/$each operations.
      def pushes
        self["$push"] ||= {}
      end

      # Get the $set operations or initialize a new one.
      #
      # @example Get the $set operations.
      #   modifiers.sets
      #
      # @return [ Hash ] The $set operations.
      def sets
        self["$set"] ||= {}
      end

      # Get the $unset operations or initialize a new one.
      #
      # @example Get the $unset operations.
      #   modifiers.unsets
      #
      # @return [ Hash ] The $unset operations.
      def unsets
        self["$unset"] ||= {}
      end
    end
  end
end
