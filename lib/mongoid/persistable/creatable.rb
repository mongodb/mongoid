# frozen_string_literal: true

module Mongoid
  module Persistable
    # Defines behavior for persistence operations that create new documents.
    module Creatable
      extend ActiveSupport::Concern

      # Insert a new document into the database. Will return the document
      # itself whether or not the save was successful.
      #
      # @example Insert a document.
      #   document.insert
      #
      # @param [ Hash ] options Options to pass to insert.
      #
      # @return [ Document ] The persisted document.
      def insert(options = {})
        prepare_insert(options) do
          if embedded?
            insert_as_embedded
          else
            insert_as_root
          end
        end
      end

      private

      # Get the atomic insert for embedded documents, either a push or set.
      #
      # @api private
      #
      # @example Get the inserts.
      #   document.inserts
      #
      # @return [ Hash ] The insert ops.
      def atomic_inserts
        { atomic_insert_modifier => { atomic_position => as_attributes } }
      end

      # Determine whether merging the touch updates into the insert
      # operations would produce an update whose operators target both a
      # path and one of its ancestors or descendants. MongoDB rejects such
      # an update with error 40. This can happen for embeds_many inserts,
      # where the operations target the array (via $push) but the touches
      # include a path inside that array (e.g. items.0.updated_at) when a
      # sibling has a pending touch.
      #
      # @api private
      #
      # @param [ Hash ] operations The atomic insert operations.
      # @param [ Hash ] touches The touch updates to merge.
      #
      # @return [ true | false ] Whether any touch path conflicts with a
      #   path the insert operations target.
      def conflicting_touch_paths?(operations, touches)
        targeted = operations.each_value.flat_map do |doc|
          doc.respond_to?(:keys) ? doc.keys.map(&:to_s) : []
        end

        touches.each_key.any? do |touch_path|
          path = touch_path.to_s
          targeted.any? do |target|
            path == target || path.start_with?("#{target}.") ||
              target.start_with?("#{path}.")
          end
        end
      end

      # Rewrite the indices in the touch updates to the positional operator,
      # as the final update will do to the merged operations. The touches of
      # the parent chain target the inserted element, so rewriting them is
      # safe, and merging the rewritten keys into the operations lets the
      # final update reuse them as-is. A pending touch on a different element
      # of the same array, however, would be rewritten to the same positional
      # path and silently touch the wrong document; in that case this method
      # returns nil and the caller persists the touch updates in their own
      # round-trip after the insert instead of merging them.
      #
      # @api private
      #
      # @param [ Hash ] selector The update selector.
      # @param [ Document ] parent The parent document being touched.
      # @param [ Symbol, String, nil ] field The parent's custom touch field.
      # @param [ Hash ] touches The touch updates to rewrite.
      #
      # @return [ Hash | nil ] The rewritten touch updates, or nil if any
      #   touch would be misdirected by the rewriting.
      def rewritten_touch_updates(selector, parent, field, touches)
        rewritten = positionally(selector, { '$set' => touches })['$set']

        touches.each_key do |key|
          path = key.to_s
          next if rewritten.key?(path)

          return nil unless chain_touch_path?(parent, field, path)
        end
        rewritten
      end

      # Whether the given path is written by a touch of the parent chain and
      # so is safe to merge into the insert.
      #
      # @api private
      #
      # @param [ Document ] parent The parent document being touched.
      # @param [ Symbol, String, nil ] field The parent's custom touch field.
      # @param [ String ] path The touch path.
      #
      # @return [ true | false ] Whether the path belongs to the parent chain.
      def chain_touch_path?(parent, field, path)
        node = parent
        field = parent.database_field_name(field) if field

        loop do
          if node.respond_to?(:updated_at=)
            updated_at = node.database_field_name(:updated_at)
            return true if path == node.atomic_attribute_name(updated_at).to_s
          end

          if node.equal?(parent) && field &&
             path == node.atomic_attribute_name(field).to_s
            return true
          end

          break unless node._touchable_parent?

          node = node._parent
        end
        false
      end

      # Insert the embedded document.
      #
      # When the parent association is touchable (which is the default for
      # +embedded_in+), the touch updates are merged into the same
      # +update_one+ call that performs the insert. This avoids a second
      # round-trip that the +after_save+ touch callback would otherwise
      # issue. The merge is skipped when a touch path would conflict with a
      # path the insert targets (see +conflicting_touch_paths?+) or when
      # rewriting the touch indices to the positional operator would
      # misdirect a touch (see +rewritten_touch_updates+); such touches are
      # persisted in their own round-trip right after the insert, so their
      # persistence does not depend on the callback chain running.
      #
      # @api private
      #
      # @example Insert the document as embedded.
      #   document.insert_as_embedded
      #
      # @return [ Document ] The document.
      def insert_as_embedded
        raise Errors::NoParent.new(self.class.name) unless _parent

        if _parent.new_record?
          _parent.insert
        else
          selector = _parent.atomic_selector
          operations = atomic_inserts

          deferred_touches = merge_touch_updates(selector, operations)

          _root.collection.find(selector).update_one(
            positionally(selector, operations),
            session: _session
          )

          _root.send(:persist_atomic_operations, '$set' => deferred_touches) if deferred_touches
        end
      end

      # Merge the parent chain's pending touch updates into the insert
      # operations when doing so would not produce a conflicting update
      # (see +conflicting_touch_paths?+ and +misdirected_touch_paths?+).
      # Either way, marks the touch as merged so the after_save callback
      # does not persist the updates a second time. Returns the touch
      # updates that could not be merged; they are persisted in their own
      # round-trip right after the insert, rather than relying on the
      # after_save callback, so that an aborted callback chain cannot
      # silently drop them.
      #
      # @api private
      #
      # @param [ Hash ] selector The update selector.
      # @param [ Hash ] operations The atomic insert operations, modified
      #   in place when the touches are merged.
      #
      # @return [ Hash | nil ] The deferred touch updates, if any.
      def merge_touch_updates(selector, operations)
        return nil unless _touchable_parent?

        field = _association&.inverse_association&.touch_field
        touches = _parent._gather_touch_updates(Time.current, field)
        return nil if touches.blank?

        if conflicting_touch_paths?(operations, touches)
          deferred_touches = touches
        else
          rewritten = rewritten_touch_updates(selector, _parent, field, touches)
          if rewritten
            operations['$set'] = (operations['$set'] || {}).merge(rewritten)
          else
            deferred_touches = touches
          end
        end
        Threaded.begin_touch_merged(self)
        deferred_touches
      end

      # Insert the root document.
      #
      # @api private
      #
      # @example Insert the document as root.
      #   document.insert_as_root
      #
      # @return [ Document ] The document.
      def insert_as_root
        collection.insert_one(as_attributes, session: _session)
      end

      # Post process an insert, which sets the new record attribute to false
      # and flags all the children as persisted.
      #
      # @api private
      #
      # @example Post process the insert.
      #   document.post_process_insert
      #
      # @return [ true ] true.
      def post_process_insert
        self.new_record = false
        remember_storage_options!
        flag_descendants_persisted
        true
      end

      # Prepare the insert for execution. Validates and runs callbacks, etc.
      #
      # @api private
      #
      # @example Prepare for insertion.
      #   document.prepare_insert do
      #     collection.insert(as_document)
      #   end
      #
      # @param [ Hash ] options The options.
      #
      # @return [ Document ] The document.
      def prepare_insert(options = {})
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self if performing_validations?(options) &&
                       invalid?(options[:context] || :create)

        ensure_client_compatibility!
        run_callbacks(:commit, with_children: true, skip_if: -> { in_transaction? }) do
          run_callbacks(:save, with_children: false) do
            run_callbacks(:create, with_children: false) do
              run_callbacks(:persist_parent, with_children: false) do
                _mongoid_run_child_callbacks(:save) do
                  _mongoid_run_child_callbacks(:create) do
                    result = yield(self)
                    if !result.is_a?(Document) || result.errors.empty?
                      post_process_insert
                      post_process_persist(result, options)
                    end
                  end
                end
              end
            end
          end
        end
        self
      end

      module ClassMethods
        # Create a new document. This will instantiate a new document and
        # insert it in a single call. Will always return the document
        # whether save passed or not.
        #
        # @example Create a new document.
        #   Person.create(:title => "Mr")
        #
        # @example Create multiple new documents.
        #   Person.create({ title: "Mr" }, { title: "Mrs" })
        #
        # @param [ Hash | Array ] attributes The attributes to create with, or an
        #   Array of multiple attributes for multiple documents.
        #
        # @return [ Document | Array<Document> ] The newly created document(s).
        def create(attributes = nil, &block)
          _creating do
            if attributes.is_a?(::Array)
              attributes.map { |attrs| create(attrs, &block) }
            else
              doc = new(attributes, &block)
              doc.save
              doc
            end
          end
        end

        # Create a new document. This will instantiate a new document and
        # insert it in a single call. Will always return the document
        # whether save passed or not, and if validation fails an error will be
        # raise.
        #
        # @example Create a new document.
        #   Person.create!(:title => "Mr")
        #
        # @example Create multiple new documents.
        #   Person.create!({ title: "Mr" }, { title: "Mrs" })
        #
        # @param [ Hash | Array ] attributes The attributes to create with, or an
        #   Array of multiple attributes for multiple documents.
        #
        # @return [ Document | Array<Document> ] The newly created document(s).
        def create!(attributes = nil, &block)
          _creating do
            if attributes.is_a?(::Array)
              attributes.map { |attrs| create!(attrs, &block) }
            else
              doc = new(attributes, &block)
              doc.fail_due_to_validation! unless doc.insert.errors.empty?
              doc.fail_due_to_callback!(:create!) if doc.new_record?
              doc
            end
          end
        end
      end
    end
  end
end
