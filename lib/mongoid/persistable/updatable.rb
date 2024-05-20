# frozen_string_literal: true
# rubocop:todo all

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
      # @option options [ true | false ] :touch Whether or not the updated_at
      #   attribute will be updated with the current time.
      #
      # @return [ true | false ] The result of the update.
      def prepare_update(options = {})
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        enforce_immutability_of_id_field!
        ensure_client_compatibility!
        return false if performing_validations?(options) &&
          invalid?(options[:context] || :update)
        process_flagged_destroys
        update_children = cascadable_children(:update)
        process_touch_option(options, update_children) do
          run_all_callbacks_for_update(update_children) do
            result = yield(self)
            self.previously_new_record = false
            post_process_persist(result, options)
            true
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

            # TODO: DRIVERS-716: If a new "Bulk Write" API is introduced, it may
            # become possible to handle the writes for conflicts in the following call.
            coll.find(selector).update_one(positionally(selector, updates), session: _session)

            # The following code applies updates which would cause
            # path conflicts in MongoDB, for example when changing attributes
            # of foo.0.bars while adding another foo. Each conflicting update
            # is applied using its own write.
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

      # If there is a touch option and it is false, this method will call the
      # timeless method so that the updated_at attribute is not updated. It
      # will call the timeless method on all of the cascadable children as
      # well. Note that timeless is cleared in the before_update callback.
      #
      # @param [ Hash ] options The options.
      # @param [ Array<Document> ] children The children that the :update
      #   callbacks will be executed on.
      #
      # @option options [ true | false ] :touch Whether or not the updated_at
      #   attribute will be updated with the current time.
      def process_touch_option(options, children)
        if options.fetch(:touch, true)
          yield
        else
          timeless
          children.each(&:timeless)
          suppress_touch_callbacks { yield }
        end
      end

      # Checks to see if the _id field has been modified. If it has, and if
      # the document has already been persisted, this is an error. Otherwise,
      # returns without side-effects.
      #
      # Note that if `Mongoid::Config.immutable_ids` is false, this will do
      # nothing.
      #
      # @raise [ Errors::ImmutableAttribute ] if _id has changed, and document
      #   has been persisted.
      def enforce_immutability_of_id_field!
        # special case here: we *do* allow the _id to be mutated if it was
        # previously nil. This addresses an odd case exposed in
        # has_one/proxy_spec.rb where `person.create_address` would
        # (somehow?) create the address with a nil _id first, before then
        # saving it *again* with the correct _id.

        if _id_changed? && !_id_was.nil? && persisted?
          if Mongoid::Config.immutable_ids
            raise Errors::ImmutableAttribute.new(:_id, _id)
          else
            Mongoid::Warnings.warn_mutable_ids
          end
        end
      end

      # Consolidates all the callback invocations into a single place, to
      # avoid cluttering the logic in #prepare_update.
      #
      # @param [ Array<Document> ] update_children The children that the
      #   :update callbacks will be executed on.
      def run_all_callbacks_for_update(update_children)
        run_callbacks(:commit, with_children: true, skip_if: -> { in_transaction? }) do
          run_callbacks(:save, with_children: false) do
            run_callbacks(:update, with_children: false) do
              run_callbacks(:persist_parent, with_children: false) do
                _mongoid_run_child_callbacks(:save) do
                  _mongoid_run_child_callbacks(:update, children: update_children) do
                    yield
                  end # _mongoid_run_child_callbacks :update
                end # _mongoid_run_child_callbacks :save
              end # :persist_parent
            end # :update
          end # :save
        end # :commit
      end

    end
  end
end
