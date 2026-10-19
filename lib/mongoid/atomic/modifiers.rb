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
          mods = add_to_set_conflict?(field) ? conflicting_add_to_sets : add_to_sets
          add_each_operation(mods, field, value)
          add_to_set_fields[field.split('.', 2)[0]] = field
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
          mods = pull_all_conflict?(field) ? conflicting_pull_alls : pull_alls
          add_operation(mods, field, value)
          pull_fields[field.split('.', 2)[0]] = field
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
          mods = pull_conflict?(field) ? conflicting_pulls : pulls
          mods[field] = value
          pull_fields[field.split('.', 2)[0]] = field
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
          next if field == '_id'

          mods = set_conflict?(field) ? conflicting_sets : sets
          add_operation(mods, field, value)
          set_fields[field.split('.', 2)[0]] = field
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
          field = field.to_s

          if unset_conflict?(field)
            # If the conflicting $set covers the entire parent field (not just a
            # sub-path), it writes the complete current state, which already
            # reflects this unset. Skip the $unset — it's redundant.
            next if unset_superseded_by_set?(field)

            conflicting_unsets.update(field => true)
          else
            unsets.update(field => true)
          end
          unset_fields[field.split('.', 2)[0]] = field
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
      # in conjunction with $push.
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
            mods[field]['$each'].push(val)
          end
        else
          mods[field] = { '$each' => value }
        end
      end

      # Get the $addToSet operations or initialize a new one.
      #
      # @example Get the $addToSet operations.
      #   modifiers.add_to_sets
      #
      # @return [ Hash ] The $addToSet operations.
      def add_to_sets
        self['$addToSet'] ||= {}
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
        name = field.split('.', 2)[0]
        pull_fields.has_key?(name) || push_fields.has_key?(name) ||
          add_to_set_fields.has_key?(name)
      end

      # Is the operation going to be a conflict for an $unset?
      #
      # A $push or $addToSet does not shift existing array element positions,
      # so a conflicting $unset can be safely applied in a separate write
      # afterwards. A $pull does shift positions, so the $unset is not split
      # out in that case; the operations stay in the same update and MongoDB
      # rejects the update (code 40) without changing stored data, rather
      # than risking the $unset hitting a different element.
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def unset_conflict?(field)
        key = field.split('.', 2)[0]
        return true if set_fields.has_key?(key)
        return false if pull_fields.has_key?(key)

        push_fields.has_key?(key) || add_to_set_fields.has_key?(key)
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
        name = field.split('.', 2)[0]
        set_fields.has_key?(name) || pull_fields.has_key?(name) ||
          add_to_set_fields.has_key?(name) || unset_fields.has_key?(name) ||
          (push_fields.keys.count { |item| item.split('.', 2).first == name } > 1)
      end

      # Is the operation going to be a conflict for an $addToSet?
      #
      # As with $push, an $addToSet is only split out when the other
      # operation does not shift array element positions. A conflicting
      # $pull is left as-is so MongoDB rejects the update rather than the
      # $addToSet possibly hitting a different element in a separate write.
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def add_to_set_conflict?(field)
        name = field.split('.', 2)[0]
        set_fields.has_key?(name) || push_fields.has_key?(name)
      end

      # Is the operation going to be a conflict for a $pull?
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def pull_conflict?(field)
        name = field.split('.', 2)[0]
        set_fields.has_key?(name) || push_fields.has_key?(name) ||
          add_to_set_fields.has_key?(name) || pull_all_root?(name)
      end

      # Is the operation going to be a conflict for a $pullAll?
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def pull_all_conflict?(field)
        name = field.split('.', 2)[0]
        set_fields.has_key?(name) || push_fields.has_key?(name) ||
          add_to_set_fields.has_key?(name) || pull_root?(name)
      end

      # Returns true if the $unset is made redundant by a $set that covers
      # the entire root-level field. When $set "children" is issued, the
      # current (live) state of the array already includes all pending changes
      # (e.g., embedded association removed), so a $unset for any children.*.x
      # field is unnecessary.
      #
      # @param [ String ] field the field
      def unset_superseded_by_set?(field)
        key = field.split('.', 2).first
        sets(initialize: false)&.has_key?(key)
      end

      # Get the conflicting $addToSet operations.
      #
      # @example Get the conflicting add to sets.
      #   modifiers.conflicting_add_to_sets
      #
      # @return [ Hash ] The conflicting add to set operations.
      def conflicting_add_to_sets
        conflicts['$addToSet'] ||= {}
      end

      # Get the conflicting pull modifications.
      #
      # @example Get the conflicting pulls.
      #   modifiers.conflicting_pulls
      #
      # @return [ Hash ] The conflicting pull operations.
      def conflicting_pulls
        conflicts['$pull'] ||= {}
      end

      # Get the conflicting pull all modifications.
      #
      # @example Get the conflicting pull alls.
      #   modifiers.conflicting_pull_alls
      #
      # @return [ Hash ] The conflicting pull all operations.
      def conflicting_pull_alls
        conflicts['$pullAll'] ||= {}
      end

      # Get the conflicting push modifications.
      #
      # @example Get the conflicting pushs.
      #   modifiers.conflicting_pushs
      #
      # @return [ Hash ] The conflicting push operations.
      def conflicting_pushes
        conflicts['$push'] ||= {}
      end

      # Get the conflicting set modifications.
      #
      # @example Get the conflicting sets.
      #   modifiers.conflicting_sets
      #
      # @return [ Hash ] The conflicting set operations.
      def conflicting_sets
        conflicts['$set'] ||= {}
      end

      # Get the conflicting unset modifications.
      #
      # @return [ Hash ] The conflicting unset operations.
      def conflicting_unsets
        conflicts['$unset'] ||= {}
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

      # Get the names of the fields that need to be added to sets.
      #
      # @example Get the add to set fields.
      #   modifiers.add_to_set_fields
      #
      # @return [ Array<String> ] The add to set fields.
      def add_to_set_fields
        @add_to_set_fields ||= {}
      end

      # Get the names of the fields that need to be unset.
      #
      # @example Get the unset fields.
      #   modifiers.unset_fields
      #
      # @return [ Array<String> ] The unset fields.
      def unset_fields
        @unset_fields ||= {}
      end

      # Get the $pullAll operations or initialize a new one.
      #
      # @example Get the $pullAll operations.
      #   modifiers.pull_alls
      #
      # @return [ Hash ] The $pullAll operations.
      def pull_alls
        self['$pullAll'] ||= {}
      end

      # Get the $pull operations or initialize a new one.
      #
      # @example Get the $pull operations.
      #   modifiers.pulls
      #
      # @return [ Hash ] The $pull operations.
      def pulls
        self['$pull'] ||= {}
      end

      # Get the $push/$each operations or initialize a new one.
      #
      # @example Get the $push/$each operations.
      #   modifiers.pushes
      #
      # @return [ Hash ] The $push/$each operations.
      def pushes
        self['$push'] ||= {}
      end

      # Get the $set operations or initialize a new one.
      #
      # @example Get the $set operations.
      #   modifiers.sets
      #
      # @return [ Hash ] The $set operations.
      def sets(initialize: true)
        return self['$set'] unless initialize

        self['$set'] ||= {}
      end

      # Get the $unset operations or initialize a new one.
      #
      # @example Get the $unset operations.
      #   modifiers.unsets
      #
      # @return [ Hash ] The $unset operations.
      def unsets
        self['$unset'] ||= {}
      end

      # Is there a $pull on the given root-level field? Does not initialize
      # the $pull operations.
      #
      # @param [ String ] name The root-level field name.
      #
      # @return [ true | false ] If a $pull touches this field.
      def pull_root?(name)
        (self['$pull'] || {}).keys.any? { |key| key.split('.', 2)[0] == name }
      end

      # Is there a $pullAll on the given root-level field? Does not
      # initialize the $pullAll operations.
      #
      # @param [ String ] name The root-level field name.
      #
      # @return [ true | false ] If a $pullAll touches this field.
      def pull_all_root?(name)
        (self['$pullAll'] || {}).keys.any? { |key| key.split('.', 2)[0] == name }
      end
    end
  end
end
