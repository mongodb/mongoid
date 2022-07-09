# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that update existing
    # documents.
    module Updatable

      # Update a single attribute and persist the entire document.
      # This skips validation but fires the callbacks.
      #
      # @example Update the attribute.
      #   person.update_attribute(:title, "Sir")
      #
      # @param [ Symbol | String ] name The name of the attribute.
      # @param [ Object ] value The new value of the attribute.a
      #
      # @raise [ Errors::ReadonlyAttribute ] If the field cannot be changed due
      #   to being flagged as read-only.
      #
      # @return [ true | false ] True if save was successful, false if not.
      def update_attribute(name, value)
        as_writable_attribute!(name, value) do |access|
          normalized = name.to_s
          process_attribute(normalized, value)
          save(validate: false)
        end
      end

      # Update the document attributes in the database.
      #
      # @example Update the document's attributes
      #   document.update(:title => "Sir")
      #
      # @param [ Hash ] attributes The attributes to update.
      #
      # @return [ true | false ] True if validation passed, false if not.
      def update(attributes = {})
        assign_attributes(attributes)
        save
      end
      alias :update_attributes :update

      # Update the document attributes in the database and raise an error if
      # validation failed.
      #
      # @example Update the document's attributes.
      #   document.update!(:title => "Sir")
      #
      # @param [ Hash ] attributes The attributes to update.
      #
      # @raise [ Errors::Validations ] If validation failed.
      # @raise [ Errors::Callbacks ] If a callback returns false.
      #
      # @return [ true | false ] True if validation passed.
      def update!(attributes = {})
        result = update_attributes(attributes)
        unless result
          fail_due_to_validation! unless errors.empty?
          fail_due_to_callback!(:update_attributes!)
        end
        result
      end
      alias :update_attributes! :update!

      private

      # Initialize the atomic updates.
      #
      # @api private
      #
      # @example Initialize the atomic updates.
      #   document.init_atomic_updates
      #
      # @return [ Array<Hash> ] The updates and conflicts.
      def init_atomic_updates
        updates = atomic_updates
        conflicts = updates.delete(:conflicts) || {}
        [ updates, conflicts ]
      end

      # Prepare the update for execution. Validates and runs callbacks, etc.
      #
      # @api private
      #
      # @example Prepare for update.
      #   document.prepare_update do
      #     collection.update(atomic_selector)
      #   end
      #
      # @param [ Hash ] options The options.
      #
      # @return [ true | false ] The result of the update.
      def prepare_update(options = {})
        return false if performing_validations?(options) &&
          invalid?(options[:context] || :update)
        process_flagged_destroys
        run_callbacks(:save, with_children: false) do
          run_callbacks(:update, with_children: false) do
            run_callbacks(:persist_parent, with_children: false) do
              _mongoid_run_child_callbacks(:save) do
                _mongoid_run_child_callbacks(:update) do
                  result = yield(self)
                  self.previously_new_record = false
                  post_process_persist(result, options)
                  true
                end
              end
            end
          end
        end
      end

      # Update the document in the database.
      #
      # @example Update an existing document.
      #   document.update
      #
      # @param [ Hash ] options Options to pass to update.
      #
      # @option options [ true | false ] :validate Whether or not to validate.
      #
      # @return [ true | false ] True if succeeded, false if not.
      def update_document(options = {})
        prepare_update(options) do
          updates, conflicts = init_atomic_updates
          unless updates.empty?
            coll = collection(_root)
            selector = atomic_selector
            coll.find(selector).update_one(positionally(selector, updates), session: _session)

            # The following code applies updates which would cause
            # path conflicts in MongoDB, for example when changing attributes
            # of foo.0.bars while adding another foo. Each conflicting update
            # is applied using its own write.
            #
            # TODO: MONGOID-5026: reduce the number of writes performed by
            # more intelligently combining the writes such that there are
            # fewer conflicts.
            conflicts.each_pair do |modifier, changes|

              # Group the changes according to their root key which is
              # the top-level association name.
              # This handles at least the cases described in MONGOID-4982.
              conflicting_change_groups = changes.group_by do |key, _|
                key.split(".", 2).first
              end.values

              # Apply changes in batches. Pop one change from each
              # field-conflict group round-robin until all changes
              # have been applied.
              while batched_changes = conflicting_change_groups.map(&:pop).compact.to_h.presence
                coll.find(selector).update_one(
                  positionally(selector, modifier => batched_changes),
                  session: _session,
                )
              end
            end
          end
        end
      end
    end
  end
end
