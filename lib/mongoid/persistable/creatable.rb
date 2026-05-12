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
        prepare_insert(options)
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

      # Stage an insert entry on the current changeset.
      #
      # For root documents, adds an :insert entry. For embedded documents,
      # adds an :update entry against the root document's collection. If
      # the parent is itself a new record, inserts the parent first.
      #
      # @api private
      def _stage_insert
        if embedded?
          _stage_insert_as_embedded
        else
          _stage_insert_as_root
        end
      end

      # Stage an insert entry for a root document.
      #
      # @api private
      def _stage_insert_as_root
        entry = Changeset::Entry.new(
          type: :insert,
          collection: collection,
          selector: { '_id' => _id },
          payload: as_attributes,
          document: self,
          session: _session
        )
        Mongoid.current_changeset.add(entry)
      end

      # Stage an update entry for an embedded document.
      #
      # @api private
      def _stage_insert_as_embedded
        raise Errors::NoParent.new(self.class.name) unless _parent

        if _parent.new_record?
          _parent.insert
          return
        end

        operations = atomic_inserts

        if _touchable_parent?
          touches = _parent._gather_touch_updates(Time.current)
          if touches.present?
            operations['$set'] = touches
            Threaded.begin_touch_merged(self)
          end
        end

        entry = Changeset::Entry.new(
          type: :update,
          collection: _root.collection,
          selector: _parent.atomic_selector,
          payload: positionally(_parent.atomic_selector, operations),
          document: self,
          session: _session
        )
        Mongoid.current_changeset.add(entry)
      end

      # Prepare the insert for execution. Validates and runs callbacks, etc.
      #
      # @api private
      #
      # @example Prepare for insertion.
      #   document.prepare_insert
      #
      # @param [ Hash ] options The options.
      #
      # @return [ Document ] The document.
      def prepare_insert(options = {})
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
        return self if performing_validations?(options) &&
                       invalid?(options[:context] || :create)

        ensure_client_compatibility!
        run_callbacks(:save, with_children: false) do
          run_callbacks(:create, with_children: false) do
            run_callbacks(:persist_parent, with_children: false) do
              _mongoid_run_child_callbacks(:save) do
                _mongoid_run_child_callbacks(:create) do
                  Mongoid.changeset do
                    _stage_insert
                    post_process_persist(true, options)
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
