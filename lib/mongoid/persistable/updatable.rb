# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that update existing
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
        normalized = name.to_s
        unless attribute_writable?(normalized)
          raise Errors::ReadonlyAttribute.new(normalized, value)
        end
        setter = "#{normalized}="
        if respond_to?(setter)
          send(setter, value)
        else
          write_attribute(database_field_name(normalized), value)
        end
        save(validate: false)
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

      # Initialize the atomic updates.
      #
      # @api private
      #
      # @example Initialize the atomic updates.
      #   document.init_atomic_updates
      #
      # @return [ Array<Hash> ] The updates and conflicts.
      #
      # @since 4.0.0
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
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        prepare_update(options) do
          updates, conflicts = init_atomic_updates
          unless updates.empty?
            coll = _root.collection
            selector = atomic_selector
            coll.find(selector).update_one(positionally(selector, updates))
            conflicts.each_pair do |key, value|
              coll.find(selector).update_one(positionally(selector, { key => value }))
            end
          end
        end
      end
    end
  end
end
