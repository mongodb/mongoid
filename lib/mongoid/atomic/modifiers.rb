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
          mods = array_modification_conflict?(field) ? conflicting_add_to_sets : add_to_sets
          add_operation(mods, field, { '$each' => value })
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
          mods = array_modification_conflict?(field) ? conflicting_pulls : pull_alls
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
          pulls[field] = value
          pull_fields[field.split('.', 2)[0]] = field
        end
        modifications.each_key do |field|
          if main_has_root?('$push', field)
            move_pulls_under_root(field)
          else
            move_deeper_pulls(field)
          end
          move_conflicting_array_modifications(field)
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
        modifications.each_key { |field| move_conflicting_array_modifications(field) }
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
        conflicting, others = modifications.partition { |field| unset_separable?(field.to_s) }
        others.each do |field|
          field = field.to_s

          if unset_conflict?(field)
            next if unset_superseded_by_set?(field)

            conflicting_unsets.update(field => true)
          else
            unsets.update(field => true)
          end
        end
        conflicting.each { |field| conflicting_unsets.update(field.to_s => true) }
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

      # Determines whether an array operation conflicts with another operation.
      #
      # @param [ String ] field The field being modified.
      #
      # @return [ true | false ] Whether the field has a conflicting array operation.
      def array_modification_conflict?(field)
        main_has_root?('$push', field) || main_has_root?('$pull', field)
      end

      # Determines whether an unset can be applied independently of array changes.
      #
      # @param [ String ] field The field being modified.
      #
      # @return [ true | false ] Whether the unset can be separated.
      def unset_separable?(field)
        main_has_root?('$push', field) && !main_has_root?('$pull', field) &&
          !root_in?(conflicts['$pull'], field)
      end

      # Determines whether a main modifier contains the field's array root.
      #
      # @param [ String ] operator The modifier name.
      # @param [ String ] field The field being checked.
      #
      # @return [ true | false ] Whether the modifier contains the root.
      def main_has_root?(operator, field)
        root_in?(self[operator], field)
      end

      # Determines whether a modifier contains the root of a field.
      #
      # @param [ Hash | nil ] mods The modifier fields.
      # @param [ String ] field The field being checked.
      #
      # @return [ true | false ] Whether the root is present.
      def root_in?(mods, field)
        return false if mods.nil?

        name = field.split('.', 2)[0]
        mods.each_key.any? { |key| key.split('.', 2)[0] == name }
      end

      # Moves conflicting operations on an array root into the conflict queue.
      #
      # @param [ String ] field The field being modified.
      def move_conflicting_array_modifications(field)
        return unless array_modification_conflict?(field)

        name = field.split('.', 2)[0]
        move_modifications_to_conflicts('$addToSet', :conflicting_add_to_sets, name)
        move_modifications_to_conflicts('$pullAll', :conflicting_pulls, name)
        move_unsets_to_conflicts(name, field)
      end

      # Moves matching modifier fields into a conflict group.
      #
      # @param [ String ] operator The modifier name.
      # @param [ Symbol ] target The conflict group accessor.
      # @param [ String ] name The array root.
      def move_modifications_to_conflicts(operator, target, name)
        mods = self[operator]
        return if mods.nil?

        mods.keys.select { |key| key.split('.', 2)[0] == name }.each do |key|
          add_operation(send(target), key, mods.delete(key))
        end
        delete(operator) if mods.empty?
      end

      # Moves separable unsets on an array root into the conflict queue.
      #
      # @param [ String ] name The array root.
      # @param [ String ] field The field being modified.
      def move_unsets_to_conflicts(name, field)
        unsets_in_main = self['$unset']
        return if unsets_in_main.nil? || !unset_separable?(field)

        unsets_in_main.keys.select { |key| key.split('.', 2)[0] == name }.each do |key|
          conflicting_unsets.update(key => unsets_in_main.delete(key))
        end
        delete('$unset') if unsets_in_main.empty?
      end

      # A $push appends without changing existing array indexes, so later pulls
      # can run after it without changing the paths they target.
      # Defers pulls when a push shares their root; appending does not shift indexes.
      #
      # @param [ String ] field The field being modified.
      def move_pulls_under_root(field)
        name = field.split('.', 2)[0]
        pulls.keys.select { |key| key.split('.', 2)[0] == name }.each do |key|
          add_conflicting_pull(key, pulls.delete(key))
        end
        delete('$pull') if pulls.empty?
      end

      # Defers deeper pulls so shallower array paths are processed first.
      #
      # @param [ String ] field The field being modified.
      def move_deeper_pulls(field)
        name = field.split('.', 2)[0]
        same_root = pulls.keys.select { |key| key.split('.', 2)[0] == name }
        shallowest = same_root.map { |key| key.count('.') }.min
        same_root.select { |key| key.count('.') > shallowest }.each do |key|
          add_conflicting_pull(key, pulls.delete(key))
        end
      end

      # Adds a pull to the conflict queue in the order expected by update_document.
      #
      # @param [ String ] field The field being pulled.
      # @param [ Object ] value The pull condition.
      def add_conflicting_pull(field, value)
        conflicting = conflicts.delete('$pull') || {}
        conflicting[field] = value
        # update_document pops each conflict group, so store deeper paths first
        # to apply shallower pulls before deeper pulls.
        self[:conflicts] = { '$pull' => conflicting.sort_by { |key, _| -key.count('.') }.to_h }.merge(conflicts)
      end

      # Gets the conflicting $addToSet operations or initializes the group.
      #
      # @return [ Hash ] The conflicting $addToSet operations.
      def conflicting_add_to_sets
        conflicts['$addToSet'] ||= {}
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
        pull_fields.has_key?(name) || push_fields.has_key?(name)
      end

      # Is the operation going to be a conflict for an $unset?
      #
      # @param [ String ] field The field.
      #
      # @return [ true | false ] If this field is a conflict.
      def unset_conflict?(field)
        key = field.split('.', 2)[0]
        set_fields.has_key?(key)
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
          (push_fields.keys.count { |item| item.split('.', 2).first == name } > 1)
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
        sets(initialize: false).has_key?(key)
      end

      # Get the conflicting pull modifications.
      #
      # @example Get the conflicting pulls.
      #   modifiers.conflicting_pulls
      #
      # @return [ Hash ] The conflicting pull operations.
      def conflicting_pulls
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
    end
  end
end
