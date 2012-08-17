# encoding: utf-8
module Mongoid
  module Relations

    # This module handles the behaviour for synchronizing foreign keys between
    # both sides of a many to many relations.
    module Synchronization
      extend ActiveSupport::Concern

      # Is the document able to be synced on the inverse side? This is only if
      # the key has changed and the relation bindings have not been run.
      #
      # @example Are the foreign keys syncable?
      #   document.syncable?(metadata)
      #
      # @param [ Metadata ] metadata The relation metadata.
      #
      # @return [ true, false ] If we can sync.
      #
      # @since 2.1.0
      def syncable?(metadata)
        !synced?(metadata.foreign_key) && send(metadata.foreign_key_check)
      end

      # Get the synced foreign keys.
      #
      # @example Get the synced foreign keys.
      #   document.synced
      #
      # @return [ Hash ] The synced foreign keys.
      #
      # @since 2.1.0
      def synced
        @synced ||= {}
      end

      # Has the document been synced for the foreign key?
      #
      # @example Has the document been synced?
      #   document.synced?
      #
      # @param [ String ] foreign_key The foreign key.
      #
      # @return [ true, false ] If we can sync.
      #
      # @since 2.1.0
      def synced?(foreign_key)
        !!synced[foreign_key]
      end

      # Update the inverse keys on destroy.
      #
      # @example Update the inverse keys.
      #   document.remove_inverse_keys(metadata)
      #
      # @param [ Metadata ] meta The document metadata.
      #
      # @return [ Object ] The updated values.
      #
      # @since 2.2.1
      def remove_inverse_keys(meta)
        foreign_keys = send(meta.foreign_key)
        unless foreign_keys.nil? || foreign_keys.empty?
          meta.criteria(foreign_keys, self.class).pull(meta.inverse_foreign_key, id)
        end
      end

      # Update the inverse keys for the relation.
      #
      # @example Update the inverse keys
      #   document.update_inverse_keys(metadata)
      #
      # @param [ Metadata ] meta The document metadata.
      #
      # @return [ Object ] The updated values.
      #
      # @since 2.1.0
      def update_inverse_keys(meta)
        if changes.has_key?(meta.foreign_key)
          old, new = changes[meta.foreign_key]
          adds, subs = new - (old || []), (old || []) - new

          # If we are autosaving we don't want a duplicate to get added - the
          # $addToSet would run previously and then the $pushAll from the
          # inverse on the autosave would cause this. We delete each id from
          # what's in memory in case a mix of id addition and object addition
          # had occurred.
          if meta.autosave?
            send(meta.name).in_memory.each do |doc|
              adds.delete_one(doc.id)
            end
          end

          unless adds.empty?
            meta.criteria(adds, self.class).without_options.add_to_set(meta.inverse_foreign_key, id)
          end
          unless subs.empty?
            meta.criteria(subs, self.class).without_options.pull(meta.inverse_foreign_key, id)
          end
        end
      end

      module ClassMethods

        # Set up the syncing of many to many foreign keys.
        #
        # @example Set up the syncing.
        #   Person.synced(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @since 2.1.0
        def synced(metadata)
          unless metadata.forced_nil_inverse?
            synced_save(metadata)
            synced_destroy(metadata)
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
        #   Person.synced_save(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The class getting set up.
        #
        # @since 2.1.0
        def synced_save(metadata)
          set_callback(
            :save,
            :after,
            if: ->(doc){ doc.syncable?(metadata) }
          ) do |doc|
            doc.update_inverse_keys(metadata)
          end
          self
        end

        # Set up the sync of inverse keys that needs to happen on a destroy.
        #
        # @example Set up the destroy syncing.
        #   Person.synced_destroy(metadata)
        #
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Class ] The class getting set up.
        #
        # @since 2.2.1
        def synced_destroy(metadata)
          set_callback(
            :destroy,
            :after
          ) do |doc|
            doc.remove_inverse_keys(metadata)
          end
          self
        end
      end
    end
  end
end
