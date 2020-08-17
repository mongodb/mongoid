# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that update existing
    # documents.
    #
    # @since 4.0.0
    module Updatable

      # Update a single attribute and persist the entire document.
      # This skips validation but fires the callbacks.
      #
      # @example Update the attribute.
      #   person.update_attribute(:title, "Sir")
      #
      # @param [ Symbol, String ] name The name of the attribute.
      # @param [ Object ] value The new value of the attribute.a
      #
      # @raise [ Errors::ReadonlyAttribute ] If the field cannot be changed due
      #   to being flagged as reaodnly.
      #
      # @return [ true, false ] True if save was successfull, false if not.
      #
      # @since 2.0.0
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
      # @return [ true, false ] True if validation passed, false if not.
      #
      # @since 1.0.0
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
      # @return [ true, false ] True if validation passed.
      #
      # @since 1.0.0
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
      # @return [ true, false ] The result of the update.
      #
      # @since 4.0.0
      def prepare_update(options = {})
        return false if performing_validations?(options) &&
          invalid?(options[:context] || :update)
        process_flagged_destroys
        result = run_callbacks(:save) do
          run_callbacks(:update) do
            yield(self)
            true
          end
        end
        post_process_persist(result, options) and result
      end

      # Update the document in the database.
      #
      # @example Update an existing document.
      #   document.update
      #
      # @param [ Hash ] options Options to pass to update.
      #
      # @option options [ true, false ] :validate Whether or not to validate.
      #
      # @return [ true, false ] True if succeeded, false if not.
      #
      # @since 1.0.0
      def update_document(options = {})
        prepare_update(options) do
          update_modifier(atomic_selector, atomic_updates)
        end
      end

      def update_modifier(selector, updates)
        conflicts = updates.delete(:conflicts) || {}
        return if updates.empty?

        collection(_root).find(selector).update_one(positionally(selector, updates), session: _session)
        update_modifier(selector, conflicts)
      end
    end
  end
end
