# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced

      # This module handles the behavior for synchronizing foreign keys between
      # both sides of a many to many associations.
      module Syncable

        # Is the document able to be synced on the inverse side? This is only if
        # the key has changed and the association bindings have not been run.
        #
        # @example Are the foreign keys syncable?
        #   document._syncable?(association)
        #
        # @param [ Association ] association The association metadata.
        #
        # @return [ true | false ] If we can sync.
        def _syncable?(association)
          !_synced?(association.foreign_key) && send(association.foreign_key_check)
        end

        # Get the synced foreign keys.
        #
        # @example Get the synced foreign keys.
        #   document._synced
        #
        # @return [ Hash ] The synced foreign keys.
        def _synced
          @_synced ||= {}
        end

        # Has the document been synced for the foreign key?
        #
        # @example Has the document been synced?
        #   document._synced?
        #
        # @param [ String ] foreign_key The foreign key.
        #
        # @return [ true | false ] If we can sync.
        def _synced?(foreign_key)
          !!_synced[foreign_key]
        end

        # Update the inverse keys on destroy.
        #
        # @example Update the inverse keys.
        #   document.remove_inverse_keys(association)
        #
        # @param [ Association ] association The association.
        #
        # @return [ Object ] The updated values.
        def remove_inverse_keys(association)
          foreign_keys = send(association.foreign_key)
          unless foreign_keys.nil? || foreign_keys.empty?
            association.criteria(self, foreign_keys).pull(association.inverse_foreign_key => _id)
          end
        end

        # Update the inverse keys for the association.
        #
        # @example Update the inverse keys
        #   document.update_inverse_keys(association)
        #
        # @param [ Association ] association The document association.
        #
        # @return [ Object ] The updated values.
        def update_inverse_keys(association)
          if previous_changes.has_key?(association.foreign_key)
            old, new = previous_changes[association.foreign_key]
            adds, subs = new - (old || []), (old || []) - new

            # If we are autosaving we don't want a duplicate to get added - the
            # $addToSet would run previously and then the $push and $each from the
            # inverse on the autosave would cause this. We delete each id from
            # what's in memory in case a mix of id addition and object addition
            # had occurred.
            if association.autosave?
              send(association.name).in_memory.each do |doc|
                adds.delete_one(doc._id)
              end
            end

            unless adds.empty?
              association.criteria(self, adds).without_options.add_to_set(association.inverse_foreign_key => _id)
            end
            unless subs.empty?
              association.criteria(self, subs).without_options.pull(association.inverse_foreign_key => _id)
            end
          end
        end

        module ClassMethods

          # Set up the syncing of many to many foreign keys.
          #
          # @example Set up the syncing.
          #   Person._synced(association)
          #
          # @param [ Association ] association The association metadata.
          def _synced(association)
            unless association.forced_nil_inverse?
              synced_save(association)
              synced_destroy(association)
            end
          end

          private

          # Set up the sync of inverse keys that needs to happen on a save.
          #
          # If the foreign key field has changed and the document is not
          # synced, $addToSet the new ids, $pull the ones no longer in the
          # array from the inverse side.
          #
          # @example Set up the save syncing.
          #   Person.synced_save(association)
          #
          # @param [ Association ] association The association metadata.
          #
          # @return [ Class ] The class getting set up.
          def synced_save(association)
            set_callback(
                :save,
                :after,
                if: ->(doc) { doc._syncable?(association) }
            ) do |doc|
              doc.update_inverse_keys(association)
            end
            self
          end

          # Set up the sync of inverse keys that needs to happen on a destroy.
          #
          # @example Set up the destroy syncing.
          #   Person.synced_destroy(association)
          #
          # @param [ Association ] association The association metadata.
          #
          # @return [ Class ] The class getting set up.
          def synced_destroy(association)
            set_callback(
                :destroy,
                :after
            ) do |doc|
              doc.remove_inverse_keys(association)
            end
            self
          end
        end
      end
    end
  end
end
