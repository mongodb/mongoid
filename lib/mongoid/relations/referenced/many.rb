# encoding: utf-8
module Mongoid
  module Relations
    module Referenced

      # This class defines the behaviour for all relations that are a
      # one-to-many between documents in different collections.
      class Many < Relations::Many

        delegate :count, to: :criteria
        delegate :first, :in_memory, :last, :reset, :uniq, to: :target

        # Appends a document or array of documents to the relation. Will set
        # the parent and update the index in the process.
        #
        # @example Append a document.
        #   person.posts << post
        #
        # @example Push a document.
        #   person.posts.push(post)
        #
        # @example Concat with other documents.
        #   person.posts.concat([ post_one, post_two ])
        #
        # @param [ Document, Array<Document> ] *args Any number of documents.
        #
        # @return [ Array<Document> ] The loaded docs.
        #
        # @since 2.0.0.beta.1
        def <<(*args)
          docs = args.flatten
          return concat(docs) if docs.size > 1
          if doc = docs.first
            append(doc)
            doc.save if persistable? && !_assigning? && !doc.validated?
          end
          self
        end
        alias :push :<<

        # Appends an array of documents to the relation. Performs a batch
        # insert of the documents instead of persisting one at a time.
        #
        # @example Concat with other documents.
        #   person.posts.concat([ post_one, post_two ])
        #
        # @param [ Array<Document> ] documents The docs to add.
        #
        # @return [ Array<Document> ] The documents.
        #
        # @since 2.4.0
        def concat(documents)
          docs, inserts = [], []
          documents.each do |doc|
            next unless doc
            append(doc)
            save_or_delay(doc, docs, inserts) if persistable?
          end
          persist_delayed(docs, inserts)
          self
        end

        # Build a new document from the attributes and append it to this
        # relation without saving.
        #
        # @example Build a new document on the relation.
        #   person.posts.build(:title => "A new post")
        #
        # @overload build(attributes = {}, options = {}, type = nil)
        #   @param [ Hash ] attributes The attributes of the new document.
        #   @param [ Hash ] options The scoped assignment options.
        #   @param [ Class ] type The optional subclass to build.
        #
        # @overload build(attributes = {}, type = nil)
        #   @param [ Hash ] attributes The attributes of the new document.
        #   @param [ Class ] type The optional subclass to build.
        #
        # @return [ Document ] The new document.
        #
        # @since 2.0.0.beta.1
        def build(attributes = {}, type = nil)
          doc = Factory.build(type || klass, attributes)
          append(doc)
          doc.apply_post_processed_defaults
          yield(doc) if block_given?
          doc.run_callbacks(:build) { doc }
          doc
        end
        alias :new :build

        # Delete the document from the relation. This will set the foreign key
        # on the document to nil. If the dependent options on the relation are
        # :delete or :destroy the appropriate removal will occur.
        #
        # @example Delete the document.
        #   person.posts.delete(post)
        #
        # @param [ Document ] document The document to remove.
        #
        # @return [ Document ] The matching document.
        #
        # @since 2.1.0
        def delete(document)
          execute_callback :before_remove, document
          target.delete(document) do |doc|
            if doc
              unbind_one(doc)
              cascade!(doc) if !_assigning?
            end
            execute_callback :after_remove, doc
          end
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.posts.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.posts.delete_all({ :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        #
        # @return [ Integer ] The number of documents deleted.
        #
        # @since 2.0.0.beta.1
        def delete_all(conditions = nil)
          remove_all(conditions, :delete_all)
        end

        # Destroys all related documents from the database given the supplied
        # conditions.
        #
        # @example Destroy all documents in the relation.
        #   person.posts.destroy_all
        #
        # @example Conditonally destroy all documents in the relation.
        #   person.posts.destroy_all({ :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to destroy with.
        #
        # @return [ Integer ] The number of documents destroyd.
        #
        # @since 2.0.0.beta.1
        def destroy_all(conditions = nil)
          remove_all(conditions, :destroy_all)
        end

        # Iterate over each document in the relation and yield to the provided
        # block.
        #
        # @note This will load the entire relation into memory.
        #
        # @example Iterate over the documents.
        #   person.posts.each do |post|
        #     post.save
        #   end
        #
        # @return [ Array<Document> ] The loaded docs.
        #
        # @since 2.1.0
        def each
          if block_given?
            target.each { |doc| yield(doc) }
          else
            to_enum
          end
        end

        # Determine if any documents in this relation exist in the database.
        #
        # @example Are there persisted documents?
        #   person.posts.exists?
        #
        # @return [ true, false ] True is persisted documents exist, false if not.
        def exists?
          criteria.exists?
        end

        # Find the matchind document on the association, either based on id or
        # conditions.
        #
        # @example Find by an id.
        #   person.posts.find(BSON::ObjectId.new)
        #
        # @example Find by multiple ids.
        #   person.posts.find([ BSON::ObjectId.new, BSON::ObjectId.new ])
        #
        # @note This will keep matching documents in memory for iteration
        #   later.
        #
        # @param [ BSON::ObjectId, Array<BSON::ObjectId> ] arg The ids.
        #
        # @return [ Document, Criteria ] The matching document(s).
        #
        # @since 2.0.0.beta.1
        def find(*args)
          matching = criteria.find(*args)
          Array(matching).each { |doc| target.push(doc) }
          matching
        end

        # Instantiate a new references_many relation. Will set the foreign key
        # and the base on the inverse object.
        #
        # @example Create the new relation.
        #   Referenced::Many.new(base, target, metadata)
        #
        # @param [ Document ] base The document this relation hangs off of.
        # @param [ Array<Document> ] target The target of the relation.
        # @param [ Metadata ] metadata The relation's metadata.
        #
        # @since 2.0.0.beta.1
        def initialize(base, target, metadata)
          init(base, Targets::Enumerable.new(target), metadata) do
            raise_mixed if klass.embedded? && !klass.cyclic?
          end
        end

        # Removes all associations between the base document and the target
        # documents by deleting the foreign keys and the references, orphaning
        # the target documents in the process.
        #
        # @example Nullify the relation.
        #   person.posts.nullify
        #
        # @since 2.0.0.rc.1
        def nullify
          criteria.update_all(foreign_key => nil)
          target.clear do |doc|
            unbind_one(doc)
            doc.changed_attributes.delete(foreign_key)
          end
        end
        alias :nullify_all :nullify

        # Clear the relation. Will delete the documents from the db if they are
        # already persisted.
        #
        # @example Clear the relation.
        #   person.posts.clear
        #
        # @return [ Many ] The relation emptied.
        #
        # @since 2.0.0.beta.1
        def purge
          unless __metadata.destructive?
            nullify
          else
            after_remove_error = nil
            criteria.delete_all
            many = target.clear do |doc|
              execute_callback :before_remove, doc
              unbind_one(doc)
              doc.destroyed = true
              begin
                execute_callback :after_remove, doc
              rescue => e
                after_remove_error = e
              end
            end
            raise after_remove_error if after_remove_error
            many
          end
        end
        alias :clear :purge

        # Substitutes the supplied target documents for the existing documents
        # in the relation. If the new target is nil, perform the necessary
        # deletion.
        #
        # @example Replace the relation.
        #   person.posts.substitute([ new_post ])
        #
        # @param [ Array<Document> ] replacement The replacement target.
        #
        # @return [ Many ] The relation.
        #
        # @since 2.0.0.rc.1
        def substitute(replacement)
          if replacement
            new_docs, docs = replacement.compact, []
            new_ids = new_docs.map { |doc| doc._id }
            remove_not_in(new_ids)
            new_docs.each do |doc|
              docs.push(doc) if doc.send(foreign_key) != base._id
            end
            concat(docs)
          else
            purge
          end
          self
        end

        # Get a criteria for the documents without the default scoping
        # applied.
        #
        # @example Get the unscoped criteria.
        #   person.posts.unscoped
        #
        # @return [ Criteria ] The unscoped criteria.
        #
        # @since 2.4.0
        def unscoped
          klass.unscoped.where(
            foreign_key => Conversions.flag(base._id, __metadata)
          )
        end

        private

        # Appends the document to the target array, updating the index on the
        # document at the same time.
        #
        # @example Append the document to the relation.
        #   relation.append(document)
        #
        # @param [ Document ] document The document to append to the target.
        #
        # @since 2.0.0.rc.1
        def append(document)
          document.with(@persistence_options) if @persistence_options
          with_add_callbacks(document, already_related?(document)) do
            target.push(document)
            characterize_one(document)
            bind_one(document)
          end
        end

        # Execute before/after add callbacks around the block unless the objects
        # already have a persisted relation.
        #
        # @example Execute before/after add callbacks around the block.
        #   relation.with_add_callbacks(document, false)
        #
        # @param [ Document ] document The document to append to the target.
        # @param [ true, false ] already_related Whether the document is already related
        #   to the target.
        #
        # @since 5.1.0
        def with_add_callbacks(document, already_related)
          execute_callback :before_add, document unless already_related
          yield
          execute_callback :after_add, document unless already_related
        end

        # Whether the document and the base already have a persisted relation.
        #
        # @example Is the document already related to the base.
        #   relation.already_related?(document)
        #
        # @param [ Document ] document The document to possibly append to the target.
        #
        # @return [ true, false ] Whether the document is already related to the base and the
        #   relation is persisted.
        #
        # @since 5.1.0
        def already_related?(document)
          document.persisted? &&
            document.__metadata &&
              document.respond_to?(document.__metadata.foreign_key) &&
                document.__send__(document.__metadata.foreign_key) == base.id
        end

        # Instantiate the binding associated with this relation.
        #
        # @example Get the binding.
        #   relation.binding([ address ])
        #
        # @param [ Array<Document> ] new_target The new documents to bind with.
        #
        # @return [ Binding ] The binding.
        #
        # @since 2.0.0.rc.1
        def binding
          Bindings::Referenced::Many.new(base, target, __metadata)
        end

        # Get the collection of the relation in question.
        #
        # @example Get the collection of the relation.
        #   relation.collection
        #
        # @return [ Collection ] The collection of the relation.
        #
        # @since 2.0.2
        def collection
          klass.collection
        end

        # Returns the criteria object for the target class with its documents set
        # to target.
        #
        # @example Get a criteria for the relation.
        #   relation.criteria
        #
        # @return [ Criteria ] A new criteria.
        #
        # @since 2.0.0.beta.1
        def criteria
          Many.criteria(
            __metadata,
            Conversions.flag(base.send(__metadata.primary_key), __metadata),
            base.class
          )
        end

        # Perform the necessary cascade operations for documents that just got
        # deleted or nullified.
        #
        # @example Cascade the change.
        #   relation.cascade!(document)
        #
        # @param [ Document ] document The document to cascade on.
        #
        # @return [ true, false ] If the metadata is destructive.
        #
        # @since 2.1.0
        def cascade!(document)
          if persistable?
            if __metadata.destructive?
              document.send(__metadata.dependent)
            else
              document.save
            end
          end
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
        #
        # @since 2.0.0.beta.1
        def method_missing(name, *args, &block)
          if target.respond_to?(name)
            target.send(name, *args, &block)
          else
            klass.send(:with_scope, criteria) do
              criteria.public_send(name, *args, &block)
            end
          end
        end

        # Persist all the delayed batch inserts.
        #
        # @api private
        #
        # @example Persist the delayed batch inserts.
        #   relation.persist_delayed([ doc ])
        #
        # @param [ Array<Document> ] docs The delayed inserts.
        # @param [ Array<Hash> ] inserts The raw insert document.
        #
        # @since 3.0.0
        def persist_delayed(docs, inserts)
          unless docs.empty?
            collection.insert_many(inserts)
            docs.each do |doc|
              doc.new_record = false
              doc.run_after_callbacks(:create, :save)
              doc.post_persist
            end
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
          !_binding? && (_creating? || base.persisted? && !_building?)
        end

        # Deletes all related documents from the database given the supplied
        # conditions.
        #
        # @example Delete all documents in the relation.
        #   person.posts.delete_all
        #
        # @example Conditonally delete all documents in the relation.
        #   person.posts.delete_all({ :title => "Testing" })
        #
        # @param [ Hash ] conditions Optional conditions to delete with.
        # @param [ Symbol ] The deletion method to call.
        #
        # @return [ Integer ] The number of documents deleted.
        #
        # @since 2.1.0
        def remove_all(conditions = nil, method = :delete_all)
          selector = conditions || {}
          removed = klass.send(method, selector.merge!(criteria.selector))
          target.delete_if do |doc|
            if doc.matches?(selector)
              unbind_one(doc) and true
            end
          end
          removed
        end

        # Remove all the documents in the proxy that do not have the provided
        # ids.
        #
        # @example Remove all documents without the ids.
        #   proxy.remove_not_in([ id ])
        #
        # @param [ Array<Object> ] ids The ids.
        #
        # @since 2.4.0
        def remove_not_in(ids)
          removed = criteria.not_in(_id: ids)
          if __metadata.destructive?
            removed.delete_all
          else
            removed.update_all(foreign_key => nil)
          end
          in_memory.each do |doc|
            if !ids.include?(doc._id)
              unbind_one(doc)
              target.delete(doc)
              if __metadata.destructive?
                doc.destroyed = true
              end
            end
          end
        end

        # Save a persisted document immediately or delay a new document for
        # batch insert.
        #
        # @api private
        #
        # @example Save or delay the document.
        #   relation.save_or_delay(doc, [])
        #
        # @param [ Document ] doc The document.
        # @param [ Array<Document> ] inserts The inserts.
        #
        # @since 3.0.0
        def save_or_delay(doc, docs, inserts)
          if doc.new_record? && doc.valid?(:create)
            doc.run_before_callbacks(:save, :create)
            docs.push(doc)
            inserts.push(doc.as_document)
          else
            doc.save
          end
        end

        class << self

          # Return the builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the builder.
          #   Referenced::Many.builder(meta, object)
          #
          # @param [ Document ] base The base document.
          # @param [ Metadata ] meta The metadata of the relation.
          # @param [ Document, Hash ] object A document or attributes to build
          #   with.
          #
          # @return [ Builder ] A new builder object.
          #
          # @since 2.0.0.rc.1
          def builder(base, meta, object)
            Builders::Referenced::Many.new(base, meta, object || [])
          end

          # Get the standard criteria used for querying this relation.
          #
          # @example Get the criteria.
          #   Proxy.criteria(meta, id, Model)
          #
          # @param [ Metadata ] metadata The metadata.
          # @param [ Object ] object The value of the foreign key.
          # @param [ Class ] type The optional type.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 2.1.0
          def criteria(metadata, object, type = nil)
            apply_ordering(
              with_inverse_field_criterion(
                with_polymorphic_criterion(
                  metadata.klass.where(metadata.foreign_key => object),
                  metadata,
                  type
                ),
                metadata
              ), metadata
            )
          end

          def eager_load_klass
            Relations::Eager::HasMany
          end

          # Returns true if the relation is an embedded one. In this case
          # always false.
          #
          # @example Is this relation embedded?
          #   Referenced::Many.embedded?
          #
          # @return [ false ] Always false.
          #
          # @since 2.0.0.rc.1
          def embedded?
            false
          end

          # Get the foreign key for the provided name.
          #
          # @example Get the foreign key.
          #   Referenced::Many.foreign_key(:person)
          #
          # @param [ Symbol ] name The name.
          #
          # @return [ String ] The foreign key.
          #
          # @since 3.0.0
          def foreign_key(name)
            "#{name}#{foreign_key_suffix}"
          end

          # Get the default value for the foreign key.
          #
          # @example Get the default.
          #   Referenced::Many.foreign_key_default
          #
          # @return [ nil ] Always nil.
          #
          # @since 2.0.0.rc.1
          def foreign_key_default
            nil
          end

          # Returns the suffix of the foreign key field, either "_id" or "_ids".
          #
          # @example Get the suffix for the foreign key.
          #   Referenced::Many.foreign_key_suffix
          #
          # @return [ String ] "_id"
          #
          # @since 2.0.0.rc.1
          def foreign_key_suffix
            "_id"
          end

          # Returns the macro for this relation. Used mostly as a helper in
          # reflection.
          #
          # @example Get the macro.
          #   Referenced::Many.macro
          #
          # @return [ Symbol ] :has_many
          def macro
            :has_many
          end

          # Return the nested builder that is responsible for generating the documents
          # that will be used by this relation.
          #
          # @example Get the nested builder.
          #   Referenced::Many.builder(attributes, options)
          #
          # @param [ Metadata ] metadata The relation metadata.
          # @param [ Hash ] attributes The attributes to build with.
          # @param [ Hash ] options The options for the builder.
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
          # @return [ NestedBuilder ] A newly instantiated nested builder object.
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
          # @return [ Root ] The root atomic path calculator.
          #
          # @since 2.1.0
          def path(document)
            Mongoid::Atomic::Paths::Root.new(document)
          end

          # Tells the caller if this relation is one that stores the foreign
          # key on its own objects.
          #
          # @example Does this relation store a foreign key?
          #   Referenced::Many.stores_foreign_key?
          #
          # @return [ false ] Always false.
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
              :after_add,
              :after_remove,
              :as,
              :autosave,
              :before_add,
              :before_remove,
              :dependent,
              :foreign_key,
              :order,
              :primary_key
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

          private

          # Decorate the criteria with polymorphic criteria, if applicable.
          #
          # @api private
          #
          # @example Get the criteria with polymorphic criterion.
          #   Proxy.with_polymorphic_criterion(criteria, metadata)
          #
          # @param [ Criteria ] criteria The criteria to decorate.
          # @param [ Metadata ] metadata The metadata.
          # @param [ Class ] type The optional type.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 3.0.0
          def with_polymorphic_criterion(criteria, metadata, type = nil)
            if metadata.polymorphic?
              criteria.where(metadata.type => type.name)
            else
              criteria
            end
          end

          # Decorate the criteria with inverse field criteria, if applicable.
          #
          # @api private
          #
          # @example Get the criteria with polymorphic criterion.
          #   Proxy.with_inverse_field_criterion(criteria, metadata)
          #
          # @param [ Criteria ] criteria The criteria to decorate.
          # @param [ Metadata ] metadata The metadata.
          #
          # @return [ Criteria ] The criteria.
          #
          # @since 3.0.0
          def with_inverse_field_criterion(criteria, metadata)
            inverse_metadata = metadata.inverse_metadata(metadata.klass)
            if inverse_metadata.try(:inverse_of_field)
              criteria.any_in(inverse_metadata.inverse_of_field => [ metadata.name, nil ])
            else
              criteria
            end
          end
        end
      end
    end
  end
end
