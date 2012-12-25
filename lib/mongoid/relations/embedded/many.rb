# encoding: utf-8
require "mongoid/relations/embedded/batchable"

module Mongoid
  module Relations
    module Embedded

      # This class handles the behaviour for a document that embeds many other
      # documents within in it as an array.
      class Many < Relations::Many
        include Batchable

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.addresses << address
        #
        # @example Push a document.
        #   person.addresses.push(address)
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        def <<(*args)
          docs = args.flatten
          return concat(docs) if docs.size > 1
          if doc = docs.first
            append(doc)
            doc.save if persistable? && !_assigning?
          end
          self
        end
        alias :push :<<

        # Get this relation as as its representation in the database.
        #
        # @example Convert the relation to an attributes hash.
        #   person.addresses.as_document
        #
        # @return [ Array<Hash> ] The relation as stored in the db.
        #
        # @since 2.0.0.rc.1
        def as_document
          attributes = []
          _unscoped.each do |doc|
            attributes.push(doc.as_document)
          end
          attributes
        end

        # Appends an array of documents to the relation. Performs a batch
        # insert of the documents instead of persisting one at a time.
        #
        # @example Concat with other documents.
        #   person.addresses.concat([ address_one, address_two ])
        #
        # @param [ Array<Document> ] docs The docs to add.
        #
        # @return [ Array<Document> ] The documents.
        #
        # @since 2.4.0
        def concat(docs)
          batch_insert(docs) unless docs.empty?
          self
        end

        # Builds a new document in the relation and appends it to the target.
        # Takes an optional type if you want to specify a subclass.
        #
        # @example Build a new document on the relation.
        #   person.people.build(:name => "Bozo")
        #
        # @overload build(attributes = {}, options = {}, type = nil)
        #   @param [ Hash ] attributes The attributes to build the document with.
        #   @param [ Hash ] options The scoped assignment options.
        #   @param [ Class ] type Optional class to build the document with.
        #
        # @overload build(attributes = {}, type = nil)
        #   @param [ Hash ] attributes The attributes to build the document with.
        #   @param [ Class ] type Optional class to build the document with.
        #
        # @return [ Document ] The new document.
        def build(attributes = {}, options = {}, type = nil)
          if options.is_a?(Class)
            options, type = {}, options
          end
          doc = Factory.build(type || metadata.klass, attributes, options)
          append(doc)
          doc.apply_post_processed_defaults
          yield(doc) if block_given?
          doc.run_callbacks(:build) { doc }
          doc
        end
        alias :new :build

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.addresses.clear
        #
        # @return [ Many ] The empty relation.
        def clear
          batch_clear(target.dup)
          self
        end

        # Returns a count of the number of documents in the association that have
        # actually been persisted to the database.
        #
        # Use #size if you want the total number of documents.
        #
        # @example Get the count of persisted documents.
        #   person.addresses.count
        #
        # @return [ Integer ] The total number of persisted embedded docs, as
        #   flagged by the #persisted? method.
        def count
          target.select { |doc| doc.persisted? }.size
        end

        # Delete the supplied document from the target. This method is proxied
        # in order to reindex the array after the operation occurs.
        #
        # @example Delete the document from the relation.
        #   person.addresses.delete(address)
        #
        # @param [ Document ] document The document to be deleted.
        #
        # @return [ Document, nil ] The deleted document or nil if nothing deleted.
        #
        # @since 2.0.0.rc.1
        def delete(document)
          execute_callback :before_remove, document
          doc = target.delete_one(document)
          if doc && !_binding?
            _unscoped.delete_one(doc) unless doc.paranoid?
            if _assigning?
              if doc.paranoid?
                doc.destroy(suppress: true)
              else
                base.add_atomic_pull(doc)
              end
            else
              doc.delete(suppress: true)
              unbind_one(doc)
            end
          end
          reindex
          execute_callback :after_remove, document
          doc
        end

        # For use only with Mongoid::Paranoia - will be removed in 4.0.
        #
        # @example Get the deleted documents from the relation.
        #   person.paranoid_phones.deleted
        #
        # @return [ Criteria ] The deleted documents.
        #
        # @since 3.0.10
        def deleted
          unscoped.deleted
        end

        # Delete all the documents in the association without running callbacks.
        #
        # @example Delete all documents from the relation.
        #   person.addresses.delete_all
        #
        # @example Conditionally delete documents from the relation.
        #   person.addresses.delete_all({ :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to delete.
        #
        # @return [ Integer ] The number of documents deleted.
        def delete_all(conditions = {})
          remove_all(conditions, :delete)
        end

        # Delete all the documents for which the provided block returns true.
        #
        # @example Delete the matching documents.
        #   person.addresses.delete_if do |doc|
        #     doc.state = "GA"
        #   end
        #
        # @return [ Many, Enumerator ] The relation or an enumerator if no
        #   block was provided.
        #
        # @since 3.1.0
        def delete_if
          if block_given?
            target.each do |doc|
              delete(doc) if yield(doc)
            end
            self
          else
            super
          end
        end

        # Destroy all the documents in the association whilst running callbacks.
        #
        # @example Destroy all documents from the relation.
        #   person.addresses.destroy_all
        #
        # @example Conditionally destroy documents from the relation.
        #   person.addresses.destroy_all({ :street => "Bond" })
        #
        # @param [ Hash ] conditions Conditions on which documents to destroy.
        #
        # @return [ Integer ] The number of documents destroyed.
        def destroy_all(conditions = {})
          remove_all(conditions, :destroy)
        end

        # Determine if any documents in this relation exist in the database.
        #
        # @example Are there persisted documents?
        #   person.posts.exists?
        #
        # @return [ true, false ] True is persisted documents exist, false if not.
        def exists?
          count > 0
        end

        # Finds a document in this association through several different
        # methods.
        #
        # @example Find a document by its id.
        #   person.addresses.find(Moped::BSON::ObjectId.new)
        #
        # @example Find documents for multiple ids.
        #   person.addresses.find([ Moped::BSON::ObjectId.new, Moped::BSON::ObjectId.new ])
        #
        # @param [ Array<Object> ] args Various arguments.
        #
        # @return [ Array<Document>, Document ] A single or multiple documents.
        def find(*args)
          criteria.find(*args)
        end

        # Instantiate a new embeds_many relation.
        #
        # @example Create the new relation.
        #   Many.new(person, addresses, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The child documents of the relation.
        # @param [ Metadata ] metadata The relation's metadata
        #
        # @return [ Many ] The proxy.
        def initialize(base, target, metadata)
          init(base, target, metadata) do
            target.each_with_index do |doc, index|
              integrate(doc)
              doc._index = index
            end
            @_unscoped = target.dup
            @target = scope(target)
          end
        end

        # Get all the documents in the relation that are loaded into memory.
        #
        # @example Get the in memory documents.
        #   relation.in_memory
        #
        # @return [ Array<Document> ] The documents in memory.
        #
        # @since 2.1.0
        def in_memory
          target
        end

        # Pop documents off the relation. This can be a single document or
        # multiples, and will automatically persist the changes.
        #
        # @example Pop a single document.
        #   relation.pop
        #
        # @example Pop multiple documents.
        #   relation.pop(3)
        #
        # @param [ Integer ] count The number of documents to pop, or 1 if not
        #   provided.
        #
        # @return [ Document, Array<Document> ] The popped document(s).
        #
        # @since 3.0.0
        def pop(count = nil)
          if count
            if docs = target[target.size - count, target.size]
              docs.each { |doc| delete(doc) }
            end
          else
            delete(target[-1])
          end
        end

        # Substitutes the supplied target documents for the existing documents
        # in the relation.
        #
        # @example Substitute the relation's target.
        #   person.addresses.substitute([ address ])
        #
        # @param [ Array<Document> ] docs The replacement docs.
        #
        # @return [ Many ] The proxied relation.
        #
        # @since 2.0.0.rc.1
        def substitute(docs)
          batch_replace(docs)
          self
        end

        # Return the relation with all previous scoping removed. This is the
        # exact representation of the docs in the database.
        #
        # @example Get the unscoped documents.
        #   person.addresses.unscoped
        #
        # @return [ Criteria ] The unscoped relation.
        #
        # @since 2.4.0
        def unscoped
          criterion = klass.unscoped
          criterion.embedded = true
          criterion.documents = _unscoped.delete_if(&:marked_for_destruction?)
          criterion
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append to the document.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document)
          execute_callback :before_add, document
          target.push(*scope([document]))
          _unscoped.push(document)
          integrate(document)
          document._index = _unscoped.size - 1
          execute_callback :after_add, document
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Create the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The many binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Embedded::Many.new(base, target, metadata)
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        def criteria
          criterion = klass.scoped
          criterion.embedded = true
          criterion.documents = target
          Many.apply_ordering(criterion, metadata)
        end

        # Deletes one document from the target and unscoped.
        #
        # @api private
        #
        # @example Delete one document.
        #   relation.delete_one(doc)
        #
        # @param [ Document ] document The document to delete.
        #
        # @since 2.4.7
        def delete_one(document)
          target.delete_one(document)
          _unscoped.delete_one(document)
          reindex
        end

        # Integrate the document into the relation. will set its metadata and
        # attempt to bind the inverse.
        #
        # @example Integrate the document.
        #   relation.integrate(document)
        #
        # @param [ Document ] document The document to integrate.
        #
        # @since 2.1.0
        def integrate(document)
          characterize_one(document)
          bind_one(document)
        end

        # If the target array does not respond to the supplied method then try to
        # find a named scope or criteria on the class and send the call there.
        #
        # If the method exists on the array, use the default proxy behavior.
        #
        # @param [ Symbol, String ] name The name of the method.
        # @param [ Array ] args The method args
        # @param [ Proc ] block Optional block to pass.
        #
        # @return [ Criteria, Object ] A Criteria or return value from the target.
        def method_missing(name, *args, &block)
          return super if target.respond_to?(name)
          klass.send(:with_scope, criteria) do
            criteria.send(name, *args, &block)
          end
        end

        # Are we able to persist this relation?
        #
        # @example Can we persist the relation?
        #   relation.persistable?
        #
        # @return [ true, false ] If the relation is persistable.
        #
        # @since 2.1.0
        def persistable?
          base.persisted? && !_binding?
        end

        # Reindex all the target elements. This is useful when performing
        # operations on the proxied target directly and the indices need to
        # match that on the database side.
        #
        # @example Reindex the relation.
        #   person.addresses.reindex
        #
        # @since 2.0.0.rc.1
        def reindex
          _unscoped.each_with_index do |doc, index|
            doc._index = index
          end
        end

        # Apply the metadata ordering or the default scoping to the provided
        # documents.
        #
        # @example Apply scoping.
        #   person.addresses.scope(target)
        #
        # @param [ Array<Document> ] docs The documents to scope.
        #
        # @return [ Array<Document> ] The scoped docs.
        #
        # @since 2.4.0
        def scope(docs)
          return docs unless metadata.order || metadata.klass.default_scoping?
          crit = metadata.klass.order_by(metadata.order)
          crit.embedded = true
          crit.documents = docs
          crit.entries
        end

        # Remove all documents from the relation, either with a delete or a
        # destroy depending on what this was called through.
        #
        # @example Destroy documents from the relation.
        #   relation.remove_all({ :num => 1 }, true)
        #
        # @param [ Hash ] conditions Conditions to filter by.
        # @param [ true, false ] destroy If true then destroy, else delete.
        #
        # @return [ Integer ] The number of documents removed.
        def remove_all(conditions = {}, method = :delete)
          criteria = where(conditions || {})
          removed = criteria.size
          batch_remove(criteria, method)
          removed
        end

        # Get the internal unscoped documents.
        #
        # @example Get the unscoped documents.
        #   relation._unscoped
        #
        # @return [ Array<Document> ] The unscoped documents.
        #
        # @since 2.4.0
        def _unscoped
          @_unscoped ||= []
        end

        # Set the internal unscoped documents.
        #
        # @example Set the unscoped documents.
        #   relation._unscoped = docs
        #
        # @param [ Array<Document> ] docs The documents.
        #
        # @return [ Array<Document ] The unscoped docs.
        #
        # @since 2.4.0
        def _unscoped=(docs)
          @_unscoped = docs
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Embedded::Many.builder(meta, object)
          #
          # @param [ Document ] base The base document.
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A newly instantiated builder object.
          #
          # @since 2.0.0.rc.1
          def builder(base, meta, object)
            Builders::Embedded::Many.new(base, meta, object)
          end

          # Returns true if the relation is an embedded one. In this case
          # always true.
          #
          # @example Is the relation embedded?
          #   Embedded::Many.embedded?
          #
          # @return [ true ] true.
          #
          # @since 2.0.0.rc.1
          def embedded?
            true
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::Many.foreign_key_suffix
          #
          # @return [ nil ] nil.
          #
          # @since 3.0.0
          def foreign_key_suffix
            nil
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the relation macro.
          #   Mongoid::Relations::Embedded::Many.macro
          #
          # @return [ Symbol ] :embeds_many
          #
          # @since 2.0.0.rc.1
          def macro
            :embeds_many
          end

          # Return the nested builder that is responsible for generating the
          # documents that will be used by this relation.
          #
          # @example Get the nested builder.
          #   NestedAttributes::Many.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The builder options.
          #
          # @option options [ true, false ] :allow_destroy Can documents be
          #   deleted?
          # @option options [ Integer ] :limit Max number of documents to
          #   create at once.
          # @option options [ Proc, Symbol ] :reject_if If documents match this
          #   option then they are ignored.
          # @option options [ true, false ] :update_only Only existing documents
          #   can be modified.
          #
          # @return [ NestedBuilder ] The nested attributes builder.
          #
          # @since 2.0.0.rc.1
          def nested_builder(metadata, attributes, options)
            Builders::NestedAttributes::Many.new(metadata, attributes, options)
          end

          # Get the path calculator for the supplied document.
          #
          # @example Get the path calculator.
          #   Proxy.path(document)
          #
          # @param [ Document ] document The document to calculate on.
          #
          # @return [ Mongoid::Atomic::Paths::Embedded::Many ]
          #   The embedded many atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Embedded::Many.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Embedded::Many.stores_foreign_key?
          #
          # @return [ false ] false.
          #
          # @since 2.0.0.rc.1
          def stores_foreign_key?
            false
          end

          # Get the valid options allowed with this relation.
          #
          # @example Get the valid options.
          #   Relation.valid_options
          #
          # @return [ Array<Symbol> ] The valid options.
          #
          # @since 2.1.0
          def valid_options
            [
              :as, :cascade_callbacks, :cyclic, :order, :versioned, :store_as,
              :before_add, :after_add, :before_remove, :after_remove
            ]
          end

          # Get the default validation setting for the relation. Determines if
          # by default a validates associated will occur.
          #
          # @example Get the validation default.
          #   Proxy.validation_default
          #
          # @return [ true, false ] The validation default.
          #
          # @since 2.1.9
          def validation_default
            true
          end
        end
      end
    end
  end
end
